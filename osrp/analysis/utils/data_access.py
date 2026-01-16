"""
OSRP Data Access Layer
Provides unified interface to access data from DynamoDB and S3
"""

import boto3
import pandas as pd
import numpy as np
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
import io
from PIL import Image
import json

class OSRPData:
    """
    Unified data access layer for OSRP (Open Sensing Research Platform)
    """
    
    def __init__(
        self, 
        region: str = 'us-west-2',
        sensor_table: str = 'SensorTimeSeries',
        events_table: str = 'EventLog',
        screenshots_table: str = 'ScreenshotMetadata',
        ema_table: str = 'EMAResponse',
        wearable_table: str = 'WearableData',
        data_bucket: str = None
    ):
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        self.region = region
        
        # Table names
        self.sensor_table = sensor_table
        self.events_table = events_table
        self.screenshots_table = screenshots_table
        self.ema_table = ema_table
        self.wearable_table = wearable_table
        self.data_bucket = data_bucket
        
    def get_sensor_data(
        self, 
        user_id: str, 
        sensor_type: str,
        start_time: datetime,
        end_time: datetime
    ) -> pd.DataFrame:
        """
        Retrieve sensor time series data
        
        Args:
            user_id: Participant ID
            sensor_type: Type of sensor (accelerometer, gyroscope, location, etc.)
            start_time: Start timestamp
            end_time: End timestamp
            
        Returns:
            DataFrame with sensor readings and datetime index
        """
        table = self.dynamodb.Table(self.sensor_table)
        
        response = table.query(
            KeyConditionExpression='userIdSensorType = :pk AND #ts BETWEEN :start AND :end',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':pk': f"{user_id}#{sensor_type}",
                ':start': int(start_time.timestamp() * 1000),
                ':end': int(end_time.timestamp() * 1000)
            }
        )
        
        df = pd.DataFrame(response['Items'])
        
        if not df.empty:
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df = df.set_index('timestamp').sort_index()
            
            # Expand nested data dictionary
            if 'data' in df.columns:
                data_df = pd.json_normalize(df['data'])
                df = pd.concat([df.drop('data', axis=1), data_df], axis=1)
        
        return df
    
    def get_screenshots(
        self,
        user_id: str,
        start_time: datetime,
        end_time: datetime,
        load_images: bool = False
    ) -> pd.DataFrame:
        """
        Retrieve screenshot metadata (and optionally images)
        
        Args:
            user_id: Participant ID
            start_time: Start timestamp
            end_time: End timestamp
            load_images: If True, download actual images from S3
            
        Returns:
            DataFrame with screenshot metadata and optional image data
        """
        table = self.dynamodb.Table(self.screenshots_table)
        
        response = table.query(
            KeyConditionExpression='userId = :uid AND #ts BETWEEN :start AND :end',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':uid': user_id,
                ':start': int(start_time.timestamp() * 1000),
                ':end': int(end_time.timestamp() * 1000)
            }
        )
        
        df = pd.DataFrame(response['Items'])
        
        if not df.empty:
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df = df.set_index('timestamp').sort_index()
            
            if load_images:
                df['image'] = df.apply(
                    lambda row: self._load_image(row['s3Bucket'], row['s3Key']),
                    axis=1
                )
        
        return df
    
    def get_events(
        self,
        user_id: str,
        start_time: datetime,
        end_time: datetime,
        event_type: Optional[str] = None
    ) -> pd.DataFrame:
        """
        Retrieve event log data
        
        Args:
            user_id: Participant ID
            start_time: Start timestamp
            end_time: End timestamp
            event_type: Optional filter for specific event type
            
        Returns:
            DataFrame with events
        """
        table = self.dynamodb.Table(self.events_table)
        
        key_condition = 'userId = :uid AND timestampEventType BETWEEN :start AND :end'
        expression_values = {
            ':uid': user_id,
            ':start': f"{int(start_time.timestamp() * 1000)}#",
            ':end': f"{int(end_time.timestamp() * 1000)}#~"
        }
        
        response = table.query(
            KeyConditionExpression=key_condition,
            ExpressionAttributeValues=expression_values
        )
        
        df = pd.DataFrame(response['Items'])
        
        if not df.empty:
            # Parse timestamp from composite key
            df['timestamp'] = df['timestampEventType'].apply(
                lambda x: int(x.split('#')[0])
            )
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df = df.set_index('timestamp').sort_index()
            
            if event_type:
                df = df[df['eventType'] == event_type]
        
        return df
    
    def get_wearable_data(
        self,
        user_id: str,
        source: str,
        start_time: datetime,
        end_time: datetime
    ) -> pd.DataFrame:
        """
        Retrieve wearable device data
        
        Args:
            user_id: Participant ID
            source: Data source (googlefit, polar_h10, fitbit, etc.)
            start_time: Start timestamp
            end_time: End timestamp
            
        Returns:
            DataFrame with wearable data
        """
        table = self.dynamodb.Table(self.wearable_table)
        
        response = table.query(
            KeyConditionExpression='userIdSource = :pk AND #ts BETWEEN :start AND :end',
            ExpressionAttributeNames={'#ts': 'timestamp'},
            ExpressionAttributeValues={
                ':pk': f"{user_id}#{source}",
                ':start': int(start_time.timestamp() * 1000),
                ':end': int(end_time.timestamp() * 1000)
            }
        )
        
        df = pd.DataFrame(response['Items'])
        
        if not df.empty:
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df = df.set_index('timestamp').sort_index()
            
            # Expand values dictionary
            if 'values' in df.columns:
                values_df = pd.json_normalize(df['values'])
                df = pd.concat([df.drop('values', axis=1), values_df], axis=1)
        
        return df
    
    def get_ema_responses(
        self,
        user_id: str,
        start_time: datetime,
        end_time: datetime,
        survey_id: Optional[str] = None
    ) -> pd.DataFrame:
        """
        Retrieve EMA survey responses
        
        Args:
            user_id: Participant ID
            start_time: Start timestamp
            end_time: End timestamp
            survey_id: Optional filter for specific survey
            
        Returns:
            DataFrame with survey responses
        """
        table = self.dynamodb.Table(self.ema_table)
        
        response = table.query(
            KeyConditionExpression='userId = :uid AND timestampSurveyId BETWEEN :start AND :end',
            ExpressionAttributeValues={
                ':uid': user_id,
                ':start': f"{int(start_time.timestamp() * 1000)}#",
                ':end': f"{int(end_time.timestamp() * 1000)}#~"
            }
        )
        
        df = pd.DataFrame(response['Items'])
        
        if not df.empty:
            df['timestamp'] = df['timestampSurveyId'].apply(
                lambda x: int(x.split('#')[0])
            )
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df = df.set_index('timestamp').sort_index()
            
            if survey_id:
                df = df[df['surveyId'] == survey_id]
                
            # Expand responses dictionary
            if 'responses' in df.columns:
                responses_df = pd.json_normalize(df['responses'])
                df = pd.concat([df.drop('responses', axis=1), responses_df], axis=1)
        
        return df
    
    def get_daily_summary(
        self,
        user_id: str,
        date: datetime
    ) -> Dict[str, pd.DataFrame]:
        """
        Get comprehensive daily summary for a participant
        
        Returns all data types for a single day
        
        Args:
            user_id: Participant ID
            date: Date to retrieve (any time on that day)
            
        Returns:
            Dictionary with DataFrames for each data type
        """
        start = date.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        
        summary = {
            'screenshots': self.get_screenshots(user_id, start, end),
            'accelerometer': self.get_sensor_data(user_id, 'accelerometer', start, end),
            'gyroscope': self.get_sensor_data(user_id, 'gyroscope', start, end),
            'location': self.get_sensor_data(user_id, 'location', start, end),
            'activity': self.get_sensor_data(user_id, 'activity', start, end),
            'events': self.get_events(user_id, start, end),
            'heart_rate': self.get_wearable_data(user_id, 'polar_h10', start, end),
            'steps': self.get_wearable_data(user_id, 'googlefit', start, end),
            'ema_responses': self.get_ema_responses(user_id, start, end)
        }
        
        return summary
    
    def get_participant_list(self, group_code: Optional[str] = None) -> List[str]:
        """
        Get list of all participants (optionally filtered by study group)
        
        Args:
            group_code: Optional study group filter
            
        Returns:
            List of participant IDs
        """
        table = self.dynamodb.Table('ParticipantStatus')
        
        if group_code:
            response = table.query(
                IndexName='groupCode-lastSeen-index',
                KeyConditionExpression='groupCode = :gc',
                ExpressionAttributeValues={':gc': group_code}
            )
        else:
            response = table.scan()
        
        return [item['userId'] for item in response['Items']]
    
    def compute_screen_time(
        self,
        screenshots_df: pd.DataFrame,
        threshold_seconds: int = 60
    ) -> pd.DataFrame:
        """
        Compute screen time from screenshot timestamps
        
        Args:
            screenshots_df: DataFrame of screenshots with timestamp index
            threshold_seconds: Max gap between screenshots to consider continuous
            
        Returns:
            DataFrame with screen time sessions
        """
        if screenshots_df.empty:
            return pd.DataFrame(columns=['start', 'end', 'duration_minutes', 'app'])
        
        # Calculate time differences
        time_diffs = screenshots_df.index.to_series().diff()
        
        # Identify session boundaries (gaps > threshold)
        session_breaks = time_diffs > pd.Timedelta(seconds=threshold_seconds)
        
        # Create session IDs
        sessions = session_breaks.cumsum()
        screenshots_df['session'] = sessions
        
        # Aggregate by session
        screen_sessions = screenshots_df.groupby('session').agg({
            'appName': lambda x: x.mode()[0] if len(x.mode()) > 0 else 'Unknown'
        })
        
        screen_sessions['start'] = screenshots_df.groupby('session').apply(
            lambda x: x.index.min()
        )
        screen_sessions['end'] = screenshots_df.groupby('session').apply(
            lambda x: x.index.max()
        )
        screen_sessions['duration_minutes'] = (
            (screen_sessions['end'] - screen_sessions['start']).dt.total_seconds() / 60
        )
        
        return screen_sessions[['start', 'end', 'duration_minutes', 'appName']]
    
    def align_multi_modal(
        self,
        dataframes: Dict[str, pd.DataFrame],
        freq: str = '1min',
        method: str = 'ffill'
    ) -> pd.DataFrame:
        """
        Align multiple data streams on common time index
        
        Args:
            dataframes: Dict of {name: DataFrame} with datetime index
            freq: Resampling frequency (e.g., '1min', '5sec', '1H')
            method: Fill method for missing values (ffill, bfill, interpolate)
            
        Returns:
            Single DataFrame with all streams aligned
        """
        aligned = pd.DataFrame()
        
        for name, df in dataframes.items():
            if df.empty:
                continue
                
            # Resample to common frequency
            resampled = df.resample(freq).mean()
            
            # Add prefix to column names
            resampled.columns = [f"{name}_{col}" for col in resampled.columns]
            
            # Merge into aligned DataFrame
            if aligned.empty:
                aligned = resampled
            else:
                aligned = aligned.join(resampled, how='outer')
        
        # Fill missing values
        if method == 'ffill':
            aligned = aligned.fillna(method='ffill')
        elif method == 'bfill':
            aligned = aligned.fillna(method='bfill')
        elif method == 'interpolate':
            aligned = aligned.interpolate()
        
        return aligned
    
    def _load_image(self, bucket: str, key: str) -> Optional[Image.Image]:
        """Load image from S3"""
        try:
            response = self.s3.get_object(Bucket=bucket, Key=key)
            image_data = response['Body'].read()
            return Image.open(io.BytesIO(image_data))
        except Exception as e:
            print(f"Error loading image {key}: {e}")
            return None


class DataAggregator:
    """
    Higher-level aggregations and feature extraction
    """
    
    @staticmethod
    def daily_activity_summary(
        activity_df: pd.DataFrame,
        steps_df: pd.DataFrame
    ) -> Dict:
        """
        Compute daily activity summary statistics
        """
        if activity_df.empty and steps_df.empty:
            return {}
        
        summary = {}
        
        # Activity recognition
        if not activity_df.empty and 'activityType' in activity_df.columns:
            activity_counts = activity_df['activityType'].value_counts()
            summary['activity_distribution'] = activity_counts.to_dict()
            
            # Time spent in each activity
            activity_time = activity_df.groupby('activityType').size()
            summary['activity_minutes'] = (activity_time * 1).to_dict()  # Assuming 1-min samples
        
        # Steps
        if not steps_df.empty and 'steps' in steps_df.columns:
            summary['total_steps'] = steps_df['steps'].sum()
            summary['avg_steps_per_hour'] = steps_df.resample('1H')['steps'].sum().mean()
        
        return summary
    
    @staticmethod
    def app_usage_summary(screenshots_df: pd.DataFrame) -> Dict:
        """
        Compute app usage summary statistics
        """
        if screenshots_df.empty:
            return {}
        
        summary = {}
        
        if 'appName' in screenshots_df.columns:
            # Most used apps
            app_counts = screenshots_df['appName'].value_counts()
            summary['top_apps'] = app_counts.head(10).to_dict()
            
            # App categories
            if 'appCategory' in screenshots_df.columns:
                category_counts = screenshots_df['appCategory'].value_counts()
                summary['category_distribution'] = category_counts.to_dict()
        
        # Temporal patterns
        screenshots_df['hour'] = screenshots_df.index.hour
        hourly_usage = screenshots_df.groupby('hour').size()
        summary['hourly_pattern'] = hourly_usage.to_dict()
        
        return summary
    
    @staticmethod
    def context_features(
        sensor_data: Dict[str, pd.DataFrame],
        window: str = '5min'
    ) -> pd.DataFrame:
        """
        Extract contextual features from multi-modal sensors
        
        Creates features like:
        - Movement variance (from accelerometer)
        - Location stability (from GPS)
        - Activity intensity
        - Device usage frequency
        """
        features = pd.DataFrame()
        
        # Accelerometer features
        if 'accelerometer' in sensor_data and not sensor_data['accelerometer'].empty:
            accel = sensor_data['accelerometer']
            
            # Movement magnitude
            if all(col in accel.columns for col in ['x', 'y', 'z']):
                accel['magnitude'] = np.sqrt(accel['x']**2 + accel['y']**2 + accel['z']**2)
                
                # Aggregate over time windows
                features['movement_mean'] = accel['magnitude'].resample(window).mean()
                features['movement_std'] = accel['magnitude'].resample(window).std()
        
        # Location features
        if 'location' in sensor_data and not sensor_data['location'].empty:
            location = sensor_data['location']
            
            if all(col in location.columns for col in ['latitude', 'longitude']):
                # Location change (simplified)
                location_resampled = location[['latitude', 'longitude']].resample(window).mean()
                lat_diff = location_resampled['latitude'].diff()
                lon_diff = location_resampled['longitude'].diff()
                features['location_change'] = np.sqrt(lat_diff**2 + lon_diff**2)
        
        return features

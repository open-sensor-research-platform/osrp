"""
End-to-End ML Pipeline
From Raw Mobile Sensing Data to Predictive Model

This notebook demonstrates a complete workflow:
1. Load and preprocess multi-modal data
2. Engineer features from time series
3. Train a predictive model
4. Evaluate and interpret results
5. Deploy for real-time predictions

Example use case: Predicting periods of high stress from behavioral/physiological signals
"""

import marimo

__generated_with = "0.9.14"
app = marimo.App()


@app.cell
def __():
    import marimo as mo
    import pandas as pd
    import numpy as np
    import plotly.graph_objects as go
    import plotly.express as px
    from datetime import datetime, timedelta
    from sklearn.model_selection import train_test_split, cross_val_score
    from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
    from sklearn.preprocessing import StandardScaler
    from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, roc_curve
    import sys
    sys.path.append('../utils')
    from data_access import OSRPData, DataAggregator

    data_access = OSRPData(region='us-west-2')
    aggregator = DataAggregator()
    
    return (mo, pd, np, go, px, datetime, timedelta, train_test_split,
            cross_val_score, RandomForestClassifier, GradientBoostingClassifier,
            StandardScaler, classification_report, confusion_matrix, 
            roc_auc_score, roc_curve, data_access, aggregator)


@app.cell
def __(mo):
    """
    Study Overview
    """
    overview = mo.md("""
    # Stress Detection from Mobile Sensing
    
    ## Objective
    Build a model to predict periods of high stress using:
    - Screen time patterns
    - Physical activity levels
    - Heart rate variability
    - App usage patterns
    - EMA self-reports (ground truth labels)
    
    ## Approach
    1. Extract features from time windows (e.g., hourly summaries)
    2. Use EMA stress ratings as labels
    3. Train supervised ML model
    4. Evaluate on held-out test set
    5. Analyze feature importance
    """)
    
    overview
    return overview,


@app.cell
def __(mo, data_access):
    """
    Configuration
    """
    participants = data_access.get_participant_list()
    
    # User selection (for this example, we'll use multiple participants)
    user_selector = mo.ui.multiselect(
        options=participants,
        value=participants[:5] if len(participants) >= 5 else participants,
        label='Select Participants'
    )
    
    # Date range
    start_date = mo.ui.date(value='2026-01-01', label='Start Date')
    end_date = mo.ui.date(value='2026-01-31', label='End Date')
    
    # Feature window
    feature_window = mo.ui.dropdown(
        options=['30min', '1H', '2H', '4H'],
        value='1H',
        label='Feature Window'
    )
    
    # Model selection
    model_type = mo.ui.dropdown(
        options=['RandomForest', 'GradientBoosting'],
        value='RandomForest',
        label='Model Type'
    )
    
    mo.vstack([
        mo.hstack([start_date, end_date]),
        user_selector,
        mo.hstack([feature_window, model_type])
    ])
    
    return (user_selector, start_date, end_date, 
            feature_window, model_type, participants)


@app.cell
def __(user_selector, start_date, end_date, datetime, data_access, pd, timedelta):
    """
    Load Data for All Participants
    """
    if user_selector.value and start_date.value and end_date.value:
        start_dt = datetime.fromisoformat(start_date.value)
        end_dt = datetime.fromisoformat(end_date.value)
        
        selected_users = list(user_selector.value)[:10]  # Limit to 10 for performance
        
        # Collect all data
        all_participant_data = []
        
        for user_id in selected_users:
            # Load each day
            current_date = start_dt
            while current_date < end_dt:
                try:
                    daily_data = data_access.get_daily_summary(user_id, current_date)
                    
                    # Store with metadata
                    all_participant_data.append({
                        'user_id': user_id,
                        'date': current_date,
                        'data': daily_data
                    })
                except Exception as e:
                    print(f"Error loading data for {user_id} on {current_date}: {e}")
                
                current_date += timedelta(days=1)
        
        data_loaded = len(all_participant_data) > 0
    else:
        all_participant_data = []
        data_loaded = False
    
    return all_participant_data, data_loaded, selected_users, start_dt, end_dt


@app.cell
def __(mo, data_loaded, all_participant_data):
    """
    Data Summary
    """
    if data_loaded:
        summary = mo.md(f"""
        ## Data Collection Summary
        
        - **Participants**: {len(set(d['user_id'] for d in all_participant_data))}
        - **Total Days**: {len(all_participant_data)}
        - **Date Range**: {min(d['date'] for d in all_participant_data).date()} to {max(d['date'] for d in all_participant_data).date()}
        """)
    else:
        summary = mo.md("Load data to see summary")
    
    summary
    return summary,


@app.cell
def __(data_loaded, all_participant_data, feature_window, pd, np):
    """
    Feature Engineering
    Extract features from time windows
    """
    if data_loaded:
        features_list = []
        
        for entry in all_participant_data:
            user_id = entry['user_id']
            date = entry['date']
            data = entry['data']
            
            # Get data streams
            screenshots = data['screenshots']
            accelerometer = data['accelerometer']
            heart_rate = data['heart_rate']
            steps = data['steps']
            ema = data['ema_responses']
            
            # Resample to feature windows
            window = feature_window.value
            
            # Generate time windows for the day
            start_time = pd.Timestamp(date)
            end_time = start_time + pd.Timedelta(days=1)
            time_index = pd.date_range(start=start_time, end=end_time, freq=window)[:-1]
            
            for window_start in time_index:
                window_end = window_start + pd.Timedelta(window)
                
                # Extract features for this window
                window_features = {
                    'user_id': user_id,
                    'timestamp': window_start,
                    'hour_of_day': window_start.hour,
                    'day_of_week': window_start.dayofweek
                }
                
                # Screen activity features
                if not screenshots.empty:
                    window_screenshots = screenshots[
                        (screenshots.index >= window_start) & 
                        (screenshots.index < window_end)
                    ]
                    window_features['screen_count'] = len(window_screenshots)
                    window_features['unique_apps'] = window_screenshots['appName'].nunique() if 'appName' in window_screenshots.columns else 0
                else:
                    window_features['screen_count'] = 0
                    window_features['unique_apps'] = 0
                
                # Movement features
                if not accelerometer.empty and all(c in accelerometer.columns for c in ['x', 'y', 'z']):
                    window_accel = accelerometer[
                        (accelerometer.index >= window_start) & 
                        (accelerometer.index < window_end)
                    ]
                    if not window_accel.empty:
                        mag = np.sqrt(window_accel['x']**2 + window_accel['y']**2 + window_accel['z']**2)
                        window_features['movement_mean'] = mag.mean()
                        window_features['movement_std'] = mag.std()
                    else:
                        window_features['movement_mean'] = 0
                        window_features['movement_std'] = 0
                else:
                    window_features['movement_mean'] = 0
                    window_features['movement_std'] = 0
                
                # Heart rate features
                if not heart_rate.empty and 'heartRate' in heart_rate.columns:
                    window_hr = heart_rate[
                        (heart_rate.index >= window_start) & 
                        (heart_rate.index < window_end)
                    ]
                    if not window_hr.empty:
                        window_features['hr_mean'] = window_hr['heartRate'].mean()
                        window_features['hr_std'] = window_hr['heartRate'].std()
                        window_features['hr_max'] = window_hr['heartRate'].max()
                    else:
                        window_features['hr_mean'] = np.nan
                        window_features['hr_std'] = np.nan
                        window_features['hr_max'] = np.nan
                else:
                    window_features['hr_mean'] = np.nan
                    window_features['hr_std'] = np.nan
                    window_features['hr_max'] = np.nan
                
                # Steps
                if not steps.empty and 'steps' in steps.columns:
                    window_steps = steps[
                        (steps.index >= window_start) & 
                        (steps.index < window_end)
                    ]
                    window_features['steps'] = window_steps['steps'].sum() if not window_steps.empty else 0
                else:
                    window_features['steps'] = 0
                
                # Label from EMA (stress rating)
                # Assuming EMA has a 'stress_level' field (1-5 scale)
                if not ema.empty:
                    window_ema = ema[
                        (ema.index >= window_start) & 
                        (ema.index < window_end)
                    ]
                    if not window_ema.empty and 'stress_level' in window_ema.columns:
                        # Take most recent EMA in window
                        stress = window_ema['stress_level'].iloc[-1]
                        # Binary classification: high stress (4-5) vs low stress (1-3)
                        window_features['label'] = 1 if stress >= 4 else 0
                        window_features['has_label'] = True
                    else:
                        window_features['label'] = np.nan
                        window_features['has_label'] = False
                else:
                    window_features['label'] = np.nan
                    window_features['has_label'] = False
                
                features_list.append(window_features)
        
        # Create DataFrame
        features_df = pd.DataFrame(features_list)
        
        # Filter to only labeled samples
        labeled_df = features_df[features_df['has_label']].copy()
        
        features_created = len(features_df)
        labeled_samples = len(labeled_df)
        
    else:
        features_df = pd.DataFrame()
        labeled_df = pd.DataFrame()
        features_created = 0
        labeled_samples = 0
    
    return (features_list, features_df, labeled_df, 
            features_created, labeled_samples, window_features)


@app.cell
def __(mo, labeled_samples, labeled_df):
    """
    Feature Summary
    """
    if labeled_samples > 0:
        # Class distribution
        class_counts = labeled_df['label'].value_counts()
        
        feature_summary = mo.md(f"""
        ## Feature Engineering Results
        
        - **Total Windows**: {len(labeled_df)}
        - **Labeled Windows**: {labeled_samples}
        - **Features**: {len(labeled_df.columns) - 4}  (excluding metadata)
        
        **Class Distribution**:
        - Low Stress (0): {class_counts.get(0, 0)} ({class_counts.get(0, 0)/labeled_samples*100:.1f}%)
        - High Stress (1): {class_counts.get(1, 0)} ({class_counts.get(1, 0)/labeled_samples*100:.1f}%)
        """)
    else:
        feature_summary = mo.md("No labeled samples available for modeling")
    
    feature_summary
    return feature_summary, class_counts


@app.cell
def __(labeled_samples, labeled_df, train_test_split, StandardScaler, np):
    """
    Prepare Training Data
    """
    if labeled_samples > 20:  # Need minimum samples
        # Select feature columns
        feature_cols = [
            'hour_of_day', 'day_of_week',
            'screen_count', 'unique_apps',
            'movement_mean', 'movement_std',
            'hr_mean', 'hr_std', 'hr_max',
            'steps'
        ]
        
        # Remove rows with missing values
        model_df = labeled_df[feature_cols + ['label']].dropna()
        
        if len(model_df) > 20:
            X = model_df[feature_cols].values
            y = model_df['label'].values
            
            # Train/test split (stratified)
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=0.2, stratify=y, random_state=42
            )
            
            # Standardize features
            scaler = StandardScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_test_scaled = scaler.transform(X_test)
            
            data_ready = True
        else:
            data_ready = False
            X_train_scaled = X_test_scaled = y_train = y_test = None
    else:
        data_ready = False
        feature_cols = []
        X_train_scaled = X_test_scaled = y_train = y_test = None
        scaler = None
    
    return (feature_cols, model_df, X, y, X_train, X_test, 
            y_train, y_test, scaler, X_train_scaled, X_test_scaled, data_ready)


@app.cell
def __(data_ready, model_type, X_train_scaled, y_train, RandomForestClassifier, GradientBoostingClassifier):
    """
    Train Model
    """
    if data_ready:
        # Select model
        if model_type.value == 'RandomForest':
            model = RandomForestClassifier(
                n_estimators=100,
                max_depth=10,
                random_state=42,
                n_jobs=-1
            )
        else:  # GradientBoosting
            model = GradientBoostingClassifier(
                n_estimators=100,
                max_depth=5,
                random_state=42
            )
        
        # Train
        model.fit(X_train_scaled, y_train)
        
        model_trained = True
    else:
        model = None
        model_trained = False
    
    return model, model_trained


@app.cell
def __(model_trained, model, X_test_scaled, y_test, classification_report, confusion_matrix, roc_auc_score):
    """
    Evaluate Model
    """
    if model_trained:
        # Predictions
        y_pred = model.predict(X_test_scaled)
        y_pred_proba = model.predict_proba(X_test_scaled)[:, 1]
        
        # Metrics
        cm = confusion_matrix(y_test, y_pred)
        report = classification_report(y_test, y_pred, output_dict=True)
        auc = roc_auc_score(y_test, y_pred_proba)
        
        eval_complete = True
    else:
        y_pred = y_pred_proba = cm = report = auc = None
        eval_complete = False
    
    return y_pred, y_pred_proba, cm, report, auc, eval_complete


@app.cell
def __(mo, eval_complete, report, auc, cm):
    """
    Display Results
    """
    if eval_complete:
        results = mo.md(f"""
        ## Model Performance
        
        **Overall Accuracy**: {report['accuracy']:.3f}
        
        **Class 0 (Low Stress)**:
        - Precision: {report['0']['precision']:.3f}
        - Recall: {report['0']['recall']:.3f}
        - F1-Score: {report['0']['f1-score']:.3f}
        
        **Class 1 (High Stress)**:
        - Precision: {report['1']['precision']:.3f}
        - Recall: {report['1']['recall']:.3f}
        - F1-Score: {report['1']['f1-score']:.3f}
        
        **ROC-AUC**: {auc:.3f}
        
        **Confusion Matrix**:
        ```
        Predicted:    Low    High
        Actual Low:   {cm[0,0]}     {cm[0,1]}
        Actual High:  {cm[1,0]}     {cm[1,1]}
        ```
        """)
    else:
        results = mo.md("Train model to see results")
    
    results
    return results,


@app.cell
def __(eval_complete, y_test, y_pred_proba, roc_curve, go):
    """
    ROC Curve
    """
    if eval_complete:
        fpr, tpr, thresholds = roc_curve(y_test, y_pred_proba)
        
        fig_roc = go.Figure()
        
        fig_roc.add_trace(go.Scatter(
            x=fpr, y=tpr,
            mode='lines',
            name='ROC Curve',
            line=dict(color='blue', width=2)
        ))
        
        fig_roc.add_trace(go.Scatter(
            x=[0, 1], y=[0, 1],
            mode='lines',
            name='Random',
            line=dict(color='gray', dash='dash')
        ))
        
        fig_roc.update_layout(
            title='ROC Curve',
            xaxis_title='False Positive Rate',
            yaxis_title='True Positive Rate',
            height=400
        )
        
        roc_plot = fig_roc
    else:
        roc_plot = None
    
    roc_plot
    return fpr, tpr, thresholds, fig_roc, roc_plot


@app.cell
def __(model_trained, model, feature_cols, pd, px):
    """
    Feature Importance
    """
    if model_trained and hasattr(model, 'feature_importances_'):
        importance_df = pd.DataFrame({
            'feature': feature_cols,
            'importance': model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        fig_importance = px.bar(
            importance_df,
            x='importance',
            y='feature',
            orientation='h',
            title='Feature Importance'
        )
        
        importance_plot = fig_importance
    else:
        importance_plot = None
    
    importance_plot
    return importance_df, fig_importance, importance_plot


@app.cell
def __(mo, model_trained, importance_df):
    """
    Interpretation
    """
    if model_trained:
        top_feature = importance_df.iloc[0]['feature']
        top_importance = importance_df.iloc[0]['importance']
        
        interpretation = mo.md(f"""
        ## Model Interpretation
        
        **Most Important Feature**: {top_feature} ({top_importance:.3f})
        
        This model uses behavioral and physiological signals to predict stress levels.
        The top features indicate what patterns are most predictive of high stress periods.
        
        **Potential Applications**:
        - Just-in-time interventions (notify user during high stress)
        - Personalized stress management recommendations
        - Long-term behavior change tracking
        - Research into stress-behavior relationships
        
        **Next Steps for Deployment**:
        1. Save model with `joblib` or `pickle`
        2. Create prediction API endpoint
        3. Deploy to SageMaker endpoint for real-time inference
        4. Integrate with mobile app for on-device predictions
        """)
    else:
        interpretation = mo.md("Train model to see interpretation")
    
    interpretation
    return interpretation, top_feature, top_importance


if __name__ == "__main__":
    app.run()

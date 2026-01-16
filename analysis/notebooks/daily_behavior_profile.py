"""
Daily Digital Behavior Profile
A comprehensive view of one participant's complete day

This Marimo notebook provides:
- Screenshot timeline showing app usage
- Activity levels throughout the day
- Heart rate patterns
- Screen time vs physical activity
- Context-aware insights
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
    from plotly.subplots import make_subplots
    from datetime import datetime, timedelta
    import sys
    sys.path.append('../utils')
    from data_access import OSRPData

    # Initialize data access
    data_access = OSRPData(
        region='us-west-2',
        data_bucket='osrp-data'
    )
    return mo, pd, np, go, px, make_subplots, datetime, timedelta, data_access


@app.cell
def __(mo, data_access):
    """
    Interactive Controls
    """
    # Get list of participants
    participants = data_access.get_participant_list()
    
    # User selection
    user_selector = mo.ui.dropdown(
        options=participants,
        value=participants[0] if participants else None,
        label='Select Participant'
    )
    
    # Date selection
    date_picker = mo.ui.date(
        value='2026-01-15',
        label='Select Date'
    )
    
    # Layout controls side by side
    mo.hstack([user_selector, date_picker], justify='start')
    return user_selector, date_picker, participants


@app.cell
def __(user_selector, date_picker, datetime, data_access):
    """
    Load Data for Selected Day
    """
    if user_selector.value and date_picker.value:
        selected_date = datetime.fromisoformat(date_picker.value)
        
        # Load all data for the day
        daily_data = data_access.get_daily_summary(
            user_id=user_selector.value,
            date=selected_date
        )
        
        # Extract individual dataframes
        screenshots = daily_data['screenshots']
        accelerometer = daily_data['accelerometer']
        activity = daily_data['activity']
        heart_rate = daily_data['heart_rate']
        steps = daily_data['steps']
        events = daily_data['events']
        ema_responses = daily_data['ema_responses']
        
        data_loaded = True
    else:
        data_loaded = False
        screenshots = None
    
    return (screenshots, accelerometer, activity, heart_rate, 
            steps, events, ema_responses, data_loaded, selected_date)


@app.cell
def __(mo, data_loaded, screenshots, steps, heart_rate):
    """
    Data Summary Statistics
    """
    if data_loaded:
        # Compute summary stats
        screenshot_count = len(screenshots) if not screenshots.empty else 0
        total_steps = steps['steps'].sum() if not steps.empty and 'steps' in steps.columns else 0
        avg_hr = heart_rate['heartRate'].mean() if not heart_rate.empty and 'heartRate' in heart_rate.columns else 0
        
        # Create summary cards
        summary = mo.md(f"""
        ## Daily Summary
        
        | Metric | Value |
        |--------|-------|
        | Screenshots Captured | {screenshot_count:,} |
        | Total Steps | {total_steps:,.0f} |
        | Average Heart Rate | {avg_hr:.0f} bpm |
        """)
    else:
        summary = mo.md("Select a participant and date to view data")
    
    summary
    return summary, screenshot_count, total_steps, avg_hr


@app.cell
def __(data_loaded, screenshots, go, make_subplots):
    """
    Timeline Visualization: App Usage Over Time
    """
    if data_loaded and not screenshots.empty:
        # Create app usage timeline
        fig_timeline = go.Figure()
        
        # Color by app category
        if 'appCategory' in screenshots.columns:
            color_map = {
                'Social': 'blue',
                'Productivity': 'green',
                'Entertainment': 'red',
                'Communication': 'purple',
                'Other': 'gray'
            }
            
            for category, group in screenshots.groupby('appCategory'):
                fig_timeline.add_trace(go.Scatter(
                    x=group.index,
                    y=[1] * len(group),  # All at y=1 for timeline
                    mode='markers',
                    name=category,
                    marker=dict(
                        size=10,
                        color=color_map.get(category, 'gray'),
                        symbol='square'
                    ),
                    text=group['appName'] if 'appName' in group.columns else None,
                    hovertemplate='%{text}<br>%{x}<extra></extra>'
                ))
        
        fig_timeline.update_layout(
            title='App Usage Timeline',
            xaxis_title='Time',
            yaxis=dict(visible=False, range=[0, 2]),
            height=200,
            showlegend=True,
            legend=dict(orientation='h', y=-0.2)
        )
        
        timeline_plot = fig_timeline
    else:
        timeline_plot = None
    
    timeline_plot
    return timeline_plot, fig_timeline


@app.cell
def __(data_loaded, accelerometer, heart_rate, steps, make_subplots, go):
    """
    Multi-Panel Activity Dashboard
    """
    if data_loaded:
        # Create subplot with 3 rows
        fig_dashboard = make_subplots(
            rows=3, cols=1,
            subplot_titles=('Movement (Accelerometer)', 'Heart Rate', 'Steps per Hour'),
            vertical_spacing=0.12,
            row_heights=[0.33, 0.33, 0.34]
        )
        
        # Plot 1: Accelerometer magnitude
        if not accelerometer.empty and all(col in accelerometer.columns for col in ['x', 'y', 'z']):
            accel_mag = np.sqrt(
                accelerometer['x']**2 + 
                accelerometer['y']**2 + 
                accelerometer['z']**2
            )
            fig_dashboard.add_trace(
                go.Scatter(x=accelerometer.index, y=accel_mag, 
                          name='Movement', line=dict(color='blue')),
                row=1, col=1
            )
        
        # Plot 2: Heart rate
        if not heart_rate.empty and 'heartRate' in heart_rate.columns:
            fig_dashboard.add_trace(
                go.Scatter(x=heart_rate.index, y=heart_rate['heartRate'],
                          name='Heart Rate', line=dict(color='red')),
                row=2, col=1
            )
        
        # Plot 3: Steps per hour
        if not steps.empty and 'steps' in steps.columns:
            hourly_steps = steps['steps'].resample('1H').sum()
            fig_dashboard.add_trace(
                go.Bar(x=hourly_steps.index, y=hourly_steps.values,
                       name='Steps', marker_color='green'),
                row=3, col=1
            )
        
        fig_dashboard.update_layout(
            height=800,
            showlegend=False,
            title_text='Activity Dashboard'
        )
        
        fig_dashboard.update_xaxes(title_text='Time', row=3, col=1)
        fig_dashboard.update_yaxes(title_text='Magnitude (g)', row=1, col=1)
        fig_dashboard.update_yaxes(title_text='BPM', row=2, col=1)
        fig_dashboard.update_yaxes(title_text='Steps', row=3, col=1)
        
        dashboard_plot = fig_dashboard
    else:
        dashboard_plot = None
    
    dashboard_plot
    return dashboard_plot, fig_dashboard, accel_mag, hourly_steps


@app.cell
def __(data_loaded, screenshots, data_access):
    """
    Screen Time Analysis
    """
    if data_loaded and not screenshots.empty:
        # Compute screen sessions
        screen_sessions = data_access.compute_screen_time(screenshots)
        
        # Total screen time
        total_screen_time = screen_sessions['duration_minutes'].sum()
        
        # Top apps by screen time
        app_time = screen_sessions.groupby('appName')['duration_minutes'].sum().sort_values(ascending=False)
        
        screen_analysis = {
            'total_minutes': total_screen_time,
            'top_apps': app_time.head(5).to_dict(),
            'num_sessions': len(screen_sessions)
        }
    else:
        screen_analysis = None
    
    return screen_sessions, screen_analysis, total_screen_time, app_time


@app.cell
def __(mo, screen_analysis):
    """
    Display Screen Time Summary
    """
    if screen_analysis:
        hours = screen_analysis['total_minutes'] / 60
        
        top_apps_md = "\n".join([
            f"- **{app}**: {mins:.1f} minutes" 
            for app, mins in screen_analysis['top_apps'].items()
        ])
        
        screen_summary = mo.md(f"""
        ### Screen Time Analysis
        
        **Total Screen Time**: {hours:.1f} hours ({screen_analysis['total_minutes']:.0f} minutes)
        
        **Number of Sessions**: {screen_analysis['num_sessions']}
        
        **Top Apps**:
        {top_apps_md}
        """)
    else:
        screen_summary = mo.md("No screen time data available")
    
    screen_summary
    return screen_summary, hours, top_apps_md


@app.cell
def __(data_loaded, activity, go):
    """
    Activity Type Distribution
    """
    if data_loaded and not activity.empty and 'activityType' in activity.columns:
        # Count activity types
        activity_counts = activity['activityType'].value_counts()
        
        fig_activity = go.Figure(data=[
            go.Pie(
                labels=activity_counts.index,
                values=activity_counts.values,
                hole=0.4
            )
        ])
        
        fig_activity.update_layout(
            title='Activity Type Distribution',
            height=400
        )
        
        activity_pie = fig_activity
    else:
        activity_pie = None
    
    activity_pie
    return activity_pie, fig_activity, activity_counts


@app.cell
def __(mo, data_loaded, screenshots, heart_rate, pd):
    """
    Correlation: Screen Time vs Heart Rate
    """
    if data_loaded and not screenshots.empty and not heart_rate.empty:
        # Align data to 5-minute windows
        screen_freq = screenshots.resample('5min').size()
        hr_freq = heart_rate['heartRate'].resample('5min').mean() if 'heartRate' in heart_rate.columns else pd.Series()
        
        # Merge on common index
        correlation_df = pd.DataFrame({
            'screen_activity': screen_freq,
            'heart_rate': hr_freq
        }).dropna()
        
        if len(correlation_df) > 10:
            corr_coef = correlation_df['screen_activity'].corr(correlation_df['heart_rate'])
            
            corr_text = mo.md(f"""
            ### Screen Activity vs Heart Rate
            
            Correlation coefficient: **{corr_coef:.3f}**
            
            {f"Moderate positive correlation - increased screen activity associated with elevated heart rate" if corr_coef > 0.3 else
             f"Weak or negative correlation" if corr_coef < 0.1 else
             "Some positive correlation observed"}
            """)
        else:
            corr_text = mo.md("Insufficient data for correlation analysis")
    else:
        corr_text = mo.md("Need both screenshot and heart rate data for correlation")
    
    corr_text
    return screen_freq, hr_freq, correlation_df, corr_coef, corr_text


@app.cell
def __(mo):
    """
    Export Options
    """
    export_info = mo.md("""
    ---
    ### Export Options
    
    **Available Exports:**
    - Raw data (CSV)
    - Visualizations (PNG/HTML)
    - Summary report (PDF)
    
    *Implement export buttons here using mo.ui.button()*
    """)
    
    export_info
    return export_info,


if __name__ == "__main__":
    app.run()

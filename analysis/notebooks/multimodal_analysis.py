"""
Multi-Modal Correlation Analysis
Analyzing relationships between digital behavior, physical activity, and physiological signals

This notebook demonstrates:
- Temporal alignment of multiple data streams
- Correlation analysis across modalities
- Pattern detection
- Feature extraction for ML
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
    from scipy import stats
    from sklearn.preprocessing import StandardScaler
    from sklearn.decomposition import PCA
    import sys
    sys.path.append('../utils')
    from data_access import OSRPData, DataAggregator

    data_access = OSRPData(region='us-west-2')
    aggregator = DataAggregator()
    return (mo, pd, np, go, px, make_subplots, datetime, timedelta, 
            stats, StandardScaler, PCA, data_access, aggregator)


@app.cell
def __(mo, data_access):
    """
    Study Configuration
    """
    participants = data_access.get_participant_list()
    
    # Multi-select for participants
    participant_selector = mo.ui.multiselect(
        options=participants,
        value=participants[:3] if len(participants) >= 3 else participants,
        label='Select Participants (up to 5)'
    )
    
    # Date range
    start_date = mo.ui.date(value='2026-01-01', label='Start Date')
    end_date = mo.ui.date(value='2026-01-07', label='End Date')
    
    # Time window for alignment
    alignment_window = mo.ui.dropdown(
        options=['1min', '5min', '15min', '1H'],
        value='5min',
        label='Alignment Window'
    )
    
    mo.vstack([
        mo.hstack([start_date, end_date], justify='start'),
        participant_selector,
        alignment_window
    ])
    return (participant_selector, start_date, end_date, 
            alignment_window, participants)


@app.cell
def __(participant_selector, start_date, end_date, datetime, data_access, pd):
    """
    Load Multi-Modal Data
    """
    if participant_selector.value and start_date.value and end_date.value:
        start_dt = datetime.fromisoformat(start_date.value)
        end_dt = datetime.fromisoformat(end_date.value)
        
        # Limit to 5 participants for performance
        selected_users = list(participant_selector.value)[:5]
        
        # Load data for each participant
        all_data = {}
        for user_id in selected_users:
            user_data = {
                'screenshots': data_access.get_screenshots(user_id, start_dt, end_dt),
                'accelerometer': data_access.get_sensor_data(user_id, 'accelerometer', start_dt, end_dt),
                'activity': data_access.get_sensor_data(user_id, 'activity', start_dt, end_dt),
                'heart_rate': data_access.get_wearable_data(user_id, 'polar_h10', start_dt, end_dt),
                'steps': data_access.get_wearable_data(user_id, 'googlefit', start_dt, end_dt),
            }
            all_data[user_id] = user_data
        
        data_loaded = True
    else:
        all_data = {}
        data_loaded = False
        selected_users = []
    
    return all_data, data_loaded, selected_users, start_dt, end_dt


@app.cell
def __(mo, data_loaded, all_data, selected_users):
    """
    Data Availability Matrix
    """
    if data_loaded:
        # Check what data exists for each participant
        availability = []
        for user_id in selected_users:
            row = {
                'Participant': user_id,
                'Screenshots': len(all_data[user_id]['screenshots']),
                'Accelerometer': len(all_data[user_id]['accelerometer']),
                'Activity': len(all_data[user_id]['activity']),
                'Heart Rate': len(all_data[user_id]['heart_rate']),
                'Steps': len(all_data[user_id]['steps'])
            }
            availability.append(row)
        
        availability_df = pd.DataFrame(availability)
        
        availability_table = mo.ui.table(availability_df)
        
        mo.md(f"""
        ## Data Availability
        
        {availability_table}
        """)
    else:
        mo.md("Load data to see availability")
    return availability, availability_df, availability_table, row


@app.cell
def __(data_loaded, all_data, selected_users, alignment_window, data_access, pd):
    """
    Align All Data Streams
    """
    if data_loaded and selected_users:
        # Align data for first participant as example
        user_id = selected_users[0]
        
        # Prepare dataframes for alignment
        dataframes = {}
        
        # Screen activity (count of screenshots per window)
        if not all_data[user_id]['screenshots'].empty:
            screen_counts = all_data[user_id]['screenshots'].resample(
                alignment_window.value
            ).size().to_frame('count')
            dataframes['screen'] = screen_counts
        
        # Accelerometer magnitude
        if not all_data[user_id]['accelerometer'].empty:
            accel = all_data[user_id]['accelerometer']
            if all(col in accel.columns for col in ['x', 'y', 'z']):
                accel_mag = np.sqrt(accel['x']**2 + accel['y']**2 + accel['z']**2).to_frame('magnitude')
                dataframes['movement'] = accel_mag
        
        # Heart rate
        if not all_data[user_id]['heart_rate'].empty and 'heartRate' in all_data[user_id]['heart_rate'].columns:
            hr_df = all_data[user_id]['heart_rate'][['heartRate']]
            dataframes['heart_rate'] = hr_df
        
        # Steps
        if not all_data[user_id]['steps'].empty and 'steps' in all_data[user_id]['steps'].columns:
            steps_df = all_data[user_id]['steps'][['steps']]
            dataframes['steps'] = steps_df
        
        # Align all streams
        aligned_data = data_access.align_multi_modal(
            dataframes,
            freq=alignment_window.value,
            method='ffill'
        )
        
        has_aligned_data = not aligned_data.empty
    else:
        aligned_data = pd.DataFrame()
        has_aligned_data = False
    
    return dataframes, aligned_data, has_aligned_data, user_id


@app.cell
def __(mo, has_aligned_data, aligned_data):
    """
    Display Aligned Data Preview
    """
    if has_aligned_data:
        preview = mo.ui.table(aligned_data.head(20))
        
        mo.md(f"""
        ### Aligned Data Preview
        
        **Shape**: {aligned_data.shape[0]} time points × {aligned_data.shape[1]} features
        
        {preview}
        """)
    else:
        mo.md("No aligned data available")
    return preview,


@app.cell
def __(has_aligned_data, aligned_data, go):
    """
    Correlation Heatmap
    """
    if has_aligned_data and len(aligned_data.columns) > 1:
        # Compute correlation matrix
        corr_matrix = aligned_data.corr()
        
        fig_corr = go.Figure(data=go.Heatmap(
            z=corr_matrix.values,
            x=corr_matrix.columns,
            y=corr_matrix.columns,
            colorscale='RdBu',
            zmid=0,
            text=corr_matrix.values.round(2),
            texttemplate='%{text}',
            textfont={"size": 10},
            colorbar=dict(title='Correlation')
        ))
        
        fig_corr.update_layout(
            title='Cross-Modal Correlation Matrix',
            height=500,
            width=600
        )
        
        corr_heatmap = fig_corr
    else:
        corr_heatmap = None
    
    corr_heatmap
    return corr_matrix, fig_corr, corr_heatmap


@app.cell
def __(has_aligned_data, aligned_data, make_subplots, go):
    """
    Time Series Comparison
    All signals on same time axis for visual comparison
    """
    if has_aligned_data:
        n_signals = len(aligned_data.columns)
        
        fig_comparison = make_subplots(
            rows=n_signals, cols=1,
            subplot_titles=aligned_data.columns.tolist(),
            vertical_spacing=0.05,
            shared_xaxes=True
        )
        
        for idx, col in enumerate(aligned_data.columns, 1):
            # Normalize each signal to 0-1 for comparison
            signal = aligned_data[col].fillna(0)
            signal_norm = (signal - signal.min()) / (signal.max() - signal.min() + 1e-10)
            
            fig_comparison.add_trace(
                go.Scatter(
                    x=aligned_data.index,
                    y=signal_norm,
                    name=col,
                    line=dict(width=1)
                ),
                row=idx, col=1
            )
        
        fig_comparison.update_layout(
            height=150 * n_signals,
            showlegend=False,
            title_text='Normalized Time Series (All Signals)'
        )
        
        comparison_plot = fig_comparison
    else:
        comparison_plot = None
    
    comparison_plot
    return fig_comparison, comparison_plot, n_signals, signal, signal_norm


@app.cell
def __(has_aligned_data, aligned_data, StandardScaler, PCA, pd):
    """
    PCA Analysis
    Reduce dimensionality to find principal patterns
    """
    if has_aligned_data and len(aligned_data.columns) >= 2:
        # Remove any rows with NaN
        pca_data = aligned_data.dropna()
        
        if len(pca_data) > 10:
            # Standardize
            scaler = StandardScaler()
            scaled_data = scaler.fit_transform(pca_data)
            
            # PCA
            pca = PCA(n_components=min(3, len(aligned_data.columns)))
            pca_components = pca.fit_transform(scaled_data)
            
            # Create DataFrame
            pca_df = pd.DataFrame(
                pca_components,
                index=pca_data.index,
                columns=[f'PC{i+1}' for i in range(pca_components.shape[1])]
            )
            
            # Explained variance
            explained_var = pca.explained_variance_ratio_
            
            has_pca = True
        else:
            has_pca = False
            pca_df = pd.DataFrame()
            explained_var = []
    else:
        has_pca = False
        pca_df = pd.DataFrame()
        explained_var = []
    
    return (pca_data, scaler, scaled_data, pca, pca_components, 
            pca_df, explained_var, has_pca)


@app.cell
def __(mo, has_pca, explained_var, pca, aligned_data):
    """
    PCA Results Summary
    """
    if has_pca:
        # Format explained variance
        var_text = "\n".join([
            f"- PC{i+1}: {var*100:.1f}%" 
            for i, var in enumerate(explained_var)
        ])
        
        # Feature contributions to PC1
        pc1_loadings = pca.components_[0]
        top_features = sorted(
            zip(aligned_data.columns, pc1_loadings),
            key=lambda x: abs(x[1]),
            reverse=True
        )[:3]
        
        features_text = "\n".join([
            f"- {feat}: {loading:.3f}"
            for feat, loading in top_features
        ])
        
        pca_summary = mo.md(f"""
        ### PCA Analysis
        
        **Explained Variance**:
        {var_text}
        
        **Top Contributors to PC1**:
        {features_text}
        """)
    else:
        pca_summary = mo.md("Insufficient data for PCA")
    
    pca_summary
    return pca_summary, var_text, pc1_loadings, top_features, features_text


@app.cell
def __(has_pca, pca_df, go):
    """
    PCA Visualization
    """
    if has_pca and len(pca_df.columns) >= 2:
        fig_pca = go.Figure()
        
        fig_pca.add_trace(go.Scatter(
            x=pca_df.index,
            y=pca_df['PC1'],
            mode='lines',
            name='PC1',
            line=dict(color='blue')
        ))
        
        if 'PC2' in pca_df.columns:
            fig_pca.add_trace(go.Scatter(
                x=pca_df.index,
                y=pca_df['PC2'],
                mode='lines',
                name='PC2',
                line=dict(color='red')
            ))
        
        fig_pca.update_layout(
            title='Principal Components Over Time',
            xaxis_title='Time',
            yaxis_title='Component Value',
            height=400
        )
        
        pca_plot = fig_pca
    else:
        pca_plot = None
    
    pca_plot
    return fig_pca, pca_plot


@app.cell
def __(mo, has_aligned_data, aligned_data, stats):
    """
    Statistical Tests
    """
    if has_aligned_data and len(aligned_data.columns) >= 2:
        # Example: Test if screen activity and movement are correlated
        cols = aligned_data.columns.tolist()
        
        if len(cols) >= 2:
            col1, col2 = cols[0], cols[1]
            
            # Clean data
            test_data = aligned_data[[col1, col2]].dropna()
            
            if len(test_data) > 10:
                # Pearson correlation test
                corr_coef, p_value = stats.pearsonr(test_data[col1], test_data[col2])
                
                # Spearman rank correlation (non-parametric)
                spearman_coef, spearman_p = stats.spearmanr(test_data[col1], test_data[col2])
                
                stats_text = mo.md(f"""
                ### Statistical Analysis: {col1} vs {col2}
                
                **Pearson Correlation**:
                - Coefficient: {corr_coef:.3f}
                - p-value: {p_value:.4f}
                - Significant: {'Yes' if p_value < 0.05 else 'No'} (α=0.05)
                
                **Spearman Rank Correlation**:
                - Coefficient: {spearman_coef:.3f}
                - p-value: {spearman_p:.4f}
                
                **Interpretation**:
                {interpret_correlation(corr_coef, p_value)}
                """)
            else:
                stats_text = mo.md("Insufficient data points for statistical testing")
        else:
            stats_text = mo.md("Need at least 2 data streams for correlation")
    else:
        stats_text = mo.md("Load aligned data for statistical analysis")
    
    stats_text
    return stats_text, test_data, corr_coef, p_value, spearman_coef, spearman_p


@app.cell
def __():
    """
    Helper function for interpretation
    """
    def interpret_correlation(r, p):
        if p >= 0.05:
            return "No statistically significant correlation detected."
        
        abs_r = abs(r)
        if abs_r < 0.3:
            strength = "weak"
        elif abs_r < 0.7:
            strength = "moderate"
        else:
            strength = "strong"
        
        direction = "positive" if r > 0 else "negative"
        
        return f"A {strength} {direction} correlation exists between these variables (p<0.05)."
    
    return interpret_correlation,


@app.cell
def __(mo):
    """
    Insights and Next Steps
    """
    insights = mo.md("""
    ---
    ## Key Insights
    
    1. **Multi-modal alignment** enables cross-signal analysis
    2. **Temporal patterns** can reveal behavior-physiology relationships
    3. **PCA** helps identify dominant patterns across modalities
    4. **Statistical testing** confirms relationships beyond chance
    
    ## Potential Research Questions
    
    - Does increased screen time predict decreased physical activity?
    - What is the relationship between movement and heart rate variability?
    - Can we predict stress from multi-modal signals?
    - Do different app categories associate with different activity levels?
    
    ## Next Steps
    
    - Add more participants for population-level analysis
    - Extract features for machine learning models
    - Build predictive models for interventions
    - Create personalized feedback dashboards
    """)
    
    insights
    return insights,


if __name__ == "__main__":
    app.run()

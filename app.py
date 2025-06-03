# This Python script is designed to be a data profiling application using Streamlit.
# It allows users to upload and analyze two datasets, providing insights into data quality,
# pattern analysis, duplicate detection, and cross-source matching, fulfilling the business
# requirement of data validation and cleansing.

import streamlit as st
import pandas as pd
import numpy as np
import re
import plotly.express as px
import plotly.graph_objects as go
from rapidfuzz import fuzz, process
from fuzzywuzzy import fuzz as fw
from io import BytesIO
from stqdm import stqdm

st.set_page_config(layout="wide", page_title="Data Profiler")
# st.title("📊 Data Profiler")
st.markdown("<h1 style='text-align:center;'>📊 Data Profiler</h1>",
            unsafe_allow_html=True)

# tab_main, tab_explore, tab_duplicates, tab_download = st.tabs([
#     "📁 Upload / Load Data", "🔍 Row/Column Counts", "🔁 Duplicate Detection", "⬇️ Export"
# ])

# with tab_main:
# Step 1: Upload two datasets
dt_1, dt_2 = st.columns(2)
with dt_1:
    st.markdown("<h3 style='text-align:center;'>Dataset 1</h3>",
                unsafe_allow_html=True)
    file1 = st.file_uploader("Upload Dataset 1", type=["csv"], key="file1")
with dt_2:
    st.markdown("<h3 style='text-align:center;'>Dataset 2</h3>",
                unsafe_allow_html=True)
    file2 = st.file_uploader("Upload Dataset 2", type=["csv"], key="file2")

# Step 2: Load both files
df1 = df2 = None
if file1:
    if file1.name.endswith(".csv"):
        df1 = pd.read_csv(file1)
    else:
        df1 = pd.read_excel(file1)

if file2:
    if file2.name.endswith(".csv"):
        df2 = pd.read_csv(file2)
    else:
        df2 = pd.read_excel(file2)

# Step 3: If both are uploaded, let user choose between them
if df1 is not None or df2 is not None:
    dataset_choice = st.radio(
        "Select Dataset to Explore",
        options=["Dataset 1", "Dataset 2"],
        horizontal=True,
        index=0 if df1 is not None else 1
    )

    df = df1 if dataset_choice == "Dataset 1" else df2
    file_name = file1.name if dataset_choice == "Dataset 1" else file2.name
    st.success(
        f"Loaded dataset with {df.shape[0]} records and {df.shape[1]} columns.")

# with tab_explore:
    st.header("1.Record & Column Counts")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    st.subheader("**Sample rows of the data:**")
    st.write(df.dropna().head())
    r_count, c_count = st.columns(2)
    with r_count:
        st.metric("Record Count", f"{df.shape[0]}")
    with c_count:
        st.metric("Column Count", f"{df.shape[1]}")
    # st.write(f"**Record Count:** {df.shape[0]}")
    # st.write(f"**Column Count:** {df.shape[1]}")

    def pattern_percentage(series, pattern):
        """Calculate the percentage of values in a series that match a given pattern."""
        return series.astype(str).str.fullmatch(pattern).mean() * 100

    def text_length(series):
        """Calculate the minimum, maximum, and average length of text in a series."""
        lengths = series.astype(str).str.len()
        return lengths.min(), lengths.max(), lengths.mean()

    # Function to calculate column profiling data
    st.header('2.Column Profiling')
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()

    def column_profiling(df):
        """
        Generate profiling data for each column in the DataFrame.
        
        Parameters:
        df (DataFrame): The input DataFrame to profile.

        Returns:
        DataFrame: A DataFrame containing profiling data for each column.
        """
        profiling_data = []
        for column in df.columns:
            data_type = df[column].dtype
            unique_values = df[column].nunique()
            uniqueness_percentage = (unique_values / len(df)) * 100
            null_count = df[column].isnull().sum()
            null_percentage = (null_count / len(df)) * 100
            min_length = df[column].astype(str).map(len).min()
            max_length = df[column].astype(str).map(len).max()
            avg_length = df[column].astype(str).map(len).mean()

            # Calculate min, max, mean, median, and std dev only for numeric columns
            if np.issubdtype(df[column].dtype, np.number):
                min_value = df[column].min()
                max_value = df[column].max()
                mean_value = df[column].mean()
                median_value = df[column].median()
                std_dev_value = df[column].std()
            else:
                min_value = None
                max_value = None
                mean_value = None
                median_value = None
                std_dev_value = None

            profiling_data.append({
                'Column Name': column,
                'Data Type': data_type,
                'Unique Values': unique_values,
                'Uniqueness %': uniqueness_percentage,
                'Null Count': null_count,
                'Null %': null_percentage,
                'Min Length': min_length,
                'Max Length': max_length,
                'Avg Length': avg_length,
                'Min Value': min_value,
                'Max Value': max_value,
                'Mean': mean_value,
                'Median': median_value,
                'Std Dev': std_dev_value
            })

        return pd.DataFrame(profiling_data)

    # Calculate column profiling data
    profiling_df = column_profiling(df)

    # Integrate the plots into Streamlit
    st.dataframe(profiling_df)
    # st.plotly_chart(fig1)
    # st.plotly_chart(fig2)

    st.subheader("📊 Column Profiling Visualizations")

    # Filter numeric metrics for fig1
    metrics_to_plot = ['Unique Values', 'Null Count']
    fig1 = go.Figure()
    for metric in metrics_to_plot:
        fig1.add_trace(go.Bar(
            x=profiling_df['Column Name'],
            y=profiling_df[metric],
            name=metric
        ))

    fig1.update_layout(
        barmode='group',
        title='📊 Count & Uniqueness Metrics per Column',
        xaxis_title='Column Name',
        yaxis_title='Count',
        legend_title='Metric',
        height=500
    )

    st.plotly_chart(fig1, use_container_width=True)

    # Create box plot for only numerical profiling metrics (mean, median, std dev)
    distribution_metrics = profiling_df[[
        'Column Name', 'Mean', 'Median', 'Std Dev']].dropna()
    fig2 = go.Figure()
    for metric in ['Mean', 'Median', 'Std Dev']:
        fig2.add_trace(go.Box(
            y=distribution_metrics[metric],
            name=metric,
            boxmean=True
        ))

    fig2.update_layout(
        title='📦 Distribution Metrics (Numeric Columns)',
        xaxis_title='Metrics',
        yaxis_title='Value',
        height=500
    )
    # st.plotly_chart(fig2, use_container_width=True)

    st.header("3.Pattern Analysis")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    pattern_analysis = pd.DataFrame({
        "Column": df.columns,
        "Email %": [pattern_percentage(df[col], r"[^@]+@[^@]+\.[^@]+") for col in df.columns],
        "Phone %": [pattern_percentage(df[col], r"^\+\d{1,3}\s?\d{9,}$") for col in df.columns],
        "Date %": [pd.to_datetime(df[col], errors='coerce').notna().mean() * 100 if df[col].dtype in ['object', 'datetime64'] else 0 for col in df.columns],
        "Numeric %": [pattern_percentage(df[col], r"^\d+(\.\d+)?$") for col in df.columns],
        # "Alphanumeric %": [df[col].astype(str).str.isalnum().mean() * 100 if df[col].dtype == object else 0 for col in df.columns],
        "Alphanumeric %": [df[col].dropna().astype(str).str.isalnum().sum() / len(df[col]) * 100 if df[col].dtype == object else 0 for col in df.columns],
    })
    patt_dict = pattern_analysis.to_dict(orient='records')
    # st.dataframe(pattern_analysis)

    # Create columns dynamically
    # columns = st.columns(len(pattern_analysis), border=True)

    # Get the total number of columns in the DataFrame
    total_columns = len(df.columns)
    cols_per_row = 5

    # Display descriptive text in each column
    for i in range(0, len(patt_dict), cols_per_row):
        cols = st.columns(min(cols_per_row, len(patt_dict) - i), border=True)
        for j, item in enumerate(patt_dict[i:i + cols_per_row]):
            column = item['Column']
            descriptions = []
            if item['Alphanumeric %'] > 0:
                descriptions.append(
                    f"Alphanumeric: {round(item['Alphanumeric %'], 2)}%")
            if item['Numeric %'] > 0:
                descriptions.append(f"Numeric: {round(item['Numeric %'], 2)}%")
            if item['Phone %'] > 0:
                descriptions.append(f"Phone: {round(item['Phone %'], 2)}%")
            if item['Date %'] > 0:
                descriptions.append(f"Date: {round(item['Date %'], 2)}%")
            # if item['Email %'] > 0:
            #     descriptions.append(f"Email: {round(item['Email %'], 2)}%")

            if descriptions:
                cols[j].write(f"**{column}**")
                cols[j].write(" ".join(descriptions))
            else:
                cols[j].write(f"**{column}**")
                cols[j].write("No significant percentage in any category")

    # print(pattern_analysis)
    i = 0
    for item in pattern_analysis[["Column", "Email %"]].to_dict(orient='records'):
        i += 1
        column = item.get('Column')
        email_match = item.get('Email %')
        if email_match > 50:
            st.subheader("Email Patterns")
            counts_table, counts_plot = st.columns(
                2, vertical_alignment='center')
            email_column = column
            email_df = df.copy()
            email_df['Email_Domain'] = email_df[email_column].astype(
                str).str.extract(r'@(.+)$')
            domain_counts = email_df['Email_Domain'].value_counts()
            domain_counts_df = pd.DataFrame(domain_counts)

            fig = px.pie(
                names=domain_counts.index,
                values=domain_counts.values,
                # title='Email Domain Distribution',
                hole=0.3
            )

            with counts_table:
                domain_counts_df
            with counts_plot:
                st.plotly_chart(fig, key=f'{str(i)}_test')

    st.header("4.Top Values per Column")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    df = df.select_dtypes(exclude='bool')
    for col in df.columns:
        i += 1
        st.subheader(f"**{col}**")
        count_df = df[col].dropna().value_counts().head(
        ).rename_axis("Value").reset_index(name="Count")
        tab_col, plot_col = st.columns(2, vertical_alignment='center')
        with tab_col:
            st.dataframe(count_df)
        fig = px.histogram(
            data_frame=count_df,
            y="Count",
            x="Value"
        )
        fig.update_xaxes(type='category')
        with plot_col:
            st.plotly_chart(fig, key=f'{str(i)}_test')

    st.header("5.Null % by Column")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    null_tab, null_plot = st.columns(2, vertical_alignment='center')
    null_percentages = df.isnull().mean() * 100
    with null_tab:
        st.dataframe(null_percentages.reset_index().rename(
            columns={"index": "Column", 0: "Null %"}))
    null_percent_df = null_percentages.to_frame(name="Percent")
    fig = px.bar(
        data_frame=null_percent_df,
        x=null_percent_df.index,
        y="Percent",
        range_y=[0, 100]
    )
    with null_plot:
        st.plotly_chart(fig)

    st.header("6.Table Summary")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    completeness = 100 - df.isnull().stack().mean() * 100
    validity = pattern_analysis[['Email %', 'Phone %', 'Date %']].mean().mean()
    uniqueness = df.nunique().mean() / len(df) * 100
    consistency = pattern_analysis[['Alphanumeric %']].mean().mean()
    overall_score = np.mean([completeness, validity, uniqueness, consistency])

    # Create columns
    col0, col1, col2, col3, col4, col5 = st.columns(6)

    # Display metrics in columns
    with col0:
        st.metric("Source", f"{file_name}")
    with col1:
        st.metric("Completeness", f"{completeness:.2f}%")
    with col2:
        st.metric("Validity", f"{validity:.2f}%")
    with col3:
        st.metric("Uniqueness", f"{uniqueness:.2f}%")
    with col4:
        st.metric("Consistency", f"{consistency:.2f}%")
    with col5:
        st.metric("Overall Score", f"{overall_score:.2f}%")

    st.header("7.Column-wise Summary")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    quality_scores = []
    for col in df.columns:
        non_null = df[col].notnull().mean() * 100
        if df[col].dtype == object and col.lower() == "email":
            valid = pattern_percentage(df[col], r"[^@]+@[^@]+\.[^@]+")
        elif df[col].dtype == object and "phone" in col.lower():
            valid = pattern_percentage(df[col], r"\d{10}")
        elif np.issubdtype(df[col].dtype, np.datetime64):
            valid = df[col].notnull().mean() * 100
        else:
            valid = 100
        unique = df[col].nunique() / len(df) * 100
        consistent = df[col].astype(str).str.isalnum(
        ).mean() * 100 if df[col].dtype == object else 100
        quality_scores.append({
            "Column": col,
            "Completeness %": non_null,
            "Validity %": valid,
            "Uniqueness %": unique,
            "Consistency %": consistent
        })
    st.dataframe(pd.DataFrame(quality_scores))

    st.header("8.Primary Key Identification")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    potential_keys = []
    for col in df.columns:
        if df[col].is_unique and df[col].notnull().all():
            potential_keys.append(col)
    if potential_keys:
        st.success(f"Potential Primary Key(s): {', '.join(potential_keys)}")
    else:
        st.warning("No single-column primary key found.")

    st.header("9. Picklist Value Extraction (Categoricals)")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    # pick_cols = st.columns(sum(1 for col in df.columns if df[col].dtype == object))
    # _i = 0
    # for col in df.columns:
    #     if df[col].dtype == object:# and df[col].nunique() < 20:
    #         with pick_cols[_i]:
    #             st.markdown(f"**{col}** (Picklist values: {df[col].nunique()})")
    #             st.dataframe(df[col].value_counts().rename_axis(
    #                 "Value").reset_index(name="Count"))
    #         _i += 1

    # Define the maximum number of columns per row
    max_columns_per_row = 5

    # Create rows of columns dynamically
    object_columns = [col for col in df.columns if df[col].dtype == object]
    total_columns = len(object_columns)

    for i in range(0, total_columns, max_columns_per_row):
        cols = st.columns(min(max_columns_per_row, total_columns - i))
        for j in range(min(max_columns_per_row, total_columns - i)):
            col_index = i + j
            col = object_columns[col_index]
            with cols[j]:
                st.markdown(
                    f"**{col}** (Picklist values: {df[col].nunique()})")
                st.dataframe(df[col].value_counts().rename_axis(
                    "Value").reset_index(name="Count"))

    st.header("10. Suggested Match & Merge Rules")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    match_rules = []
    for col in df.columns:
        if col.lower() in ["email", "id", "phone"]:
            match_type = "ExactMatch"
        elif df[col].dtype == object and df[col].str.len().mean() > 10:
            match_type = "FuzzyMatch"
        elif df[col].dtype == object:
            match_type = "CompositeMatch"
        else:
            match_type = "ExactMatch"
        match_rules.append({"Column": col, "Suggested Match Rule": match_type})
    st.dataframe(pd.DataFrame(match_rules))

    st.header("11. Survivorship Rules (Suggestions)")

    def calculate_survivorship_df(df, status_column="status", active_value="active"):
        """
        Calculate the survivorship rate based on a status column and active value.
        
        Parameters:
        df (DataFrame): The input DataFrame.
        status_column (str): The column name indicating status.
        active_value (str): The value indicating an active record.

        Returns:
        float: The survivorship rate as a percentage.
        """
        if status_column not in df.columns:
            return 0.0  # If column doesn't exist
        total_records = len(df)
        if total_records == 0:
            return 0.0
        surviving_records = df[status_column].str.lower().eq(
            active_value).sum()
        return (surviving_records / total_records) * 100

    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    # surv_rules = []
    # for col in df.columns:
    #     if "date" in col.lower():
    #         rule = "Most Recent"
    #     elif df[col].dtype == object:
    #         rule = "Longest Text"
    #     elif df[col].dtype in [int, float]:
    #         rule = "Max Value"
    #     else:
    #         rule = "Most Frequent"
    #     surv_rules.append({"Column": col, "Survivorship Rule": rule})
    # st.dataframe(pd.DataFrame(surv_rules))
    # Survivorship Rate from DataFrame
    # survivorship_rate = calculate_survivorship_df(df, status_column="status", active_value="active")

    st.subheader("Survivorship Rate")
    # st.metric(label="Rate of Active Records", value=f"{survivorship_rate:.2f}%")

    if not df.empty:
        col1, col2 = st.columns(2)

        with col1:
            # Select column to use for survivorship status
            status_col = st.selectbox(
                "Select Status Column", df.columns, key="status_col")

        with col2:
            # Select active value that signifies a "surviving" record
            if status_col:
                unique_values = df[status_col].dropna().unique()
                active_value = st.selectbox(
                    "Select Active Value", unique_values, key="active_value")

        # Function to calculate survivorship rate
        def calculate_survivorship(df, status_col, active_value):
            """
            Calculate the survivorship rate based on a status column and active value.
            
            Parameters:
            df (DataFrame): The input DataFrame.
            status_col (str): The column name indicating status.
            active_value (str): The value indicating an active record.

            Returns:
            float: The survivorship rate as a percentage.
            """
            total_records = len(df)
            surviving_records = df[status_col].eq(active_value).sum()
            if total_records == 0:
                return 0
            return (surviving_records / total_records) * 100

        # Calculate and display the rate
        survivorship_rate = calculate_survivorship(
            df, status_col, active_value)
        st.metric("Survivorship Rate", f"{survivorship_rate:.2f}%")

    st.header("12.Duplicate Detection")
    # df = df1.copy() if dataset_dup_detec == "Dataset 1" else df2.copy()
    # duplicates = df[df.duplicated()]
    # st.write(f"🔍 Found {len(duplicates)} duplicate records.")
    # st.write(f"🔍 Found {round(len(duplicates)/len(df)*100, ndigits=2)} percent of duplicate records.")
    # if not duplicates.empty:
    #     st.dataframe(duplicates.head(10))
    # ---- Load Data ----
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()

    # ---- Streamlit UI for Fuzzy Matching Columns ----
    all_categorical = df.select_dtypes(include='object').columns.tolist()
    # ['ID', 'UniqueID']
    exclude_cols = [
        col for col in all_categorical if df[col].nunique() == len(df)]
    default_cols = [col for col in all_categorical if col not in exclude_cols]

    dd_col1, dd_col2 = st.columns(2)
    with dd_col1:
        fuzzy_columns = st.multiselect(
            "Select columns for fuzzy matching", options=all_categorical, default=default_cols)
    with dd_col2:
        threshold = st.slider("Fuzzy match threshold",
                              min_value=50, max_value=100, value=90, step=5)

    # ---- Exact Duplicate Detection ----
    exact_dupes = df[df.duplicated(keep=False)].copy()
    exact_dupe_indices = set(exact_dupes.index)

    # ---- Fuzzy Duplicate Detection (with blocking optimization) ----
    matched_indices = set()
    if fuzzy_columns:
        # Create a blocking key (e.g., first character of name or phone)
        df['__fuzzy_key__'] = df[fuzzy_columns].fillna(
            '').agg(' '.join, axis=1)
        df['__block_key__'] = df[fuzzy_columns[0]].str[0].fillna('')

        for _, block_df in df.groupby('__block_key__'):
            keys = block_df['__fuzzy_key__'].tolist()
            indices = block_df.index.tolist()

            for i in range(len(keys)):
                if indices[i] in matched_indices:
                    continue
                matches = process.extract(
                    keys[i], keys, scorer=fuzz.token_sort_ratio, limit=None)
                for match_text, score, match_idx in matches:
                    idx_j = indices[match_idx]
                    if score >= threshold and indices[i] != idx_j:
                        matched_indices.add(indices[i])
                        matched_indices.add(idx_j)

        fuzzy_dupe_indices = matched_indices
        df.drop(columns=['__fuzzy_key__', '__block_key__'], inplace=True)
    else:
        fuzzy_dupe_indices = set()

    fuzzy_dupes = df.loc[list(fuzzy_dupe_indices)].copy()

    # ---- Classify Duplicates by Type ----
    only_exact = exact_dupe_indices - fuzzy_dupe_indices
    only_fuzzy = fuzzy_dupe_indices - exact_dupe_indices
    both = exact_dupe_indices & fuzzy_dupe_indices

    # Map duplicate types
    duplicate_types = {}
    for idx in only_exact:
        duplicate_types[idx] = "Exact"
    for idx in only_fuzzy:
        duplicate_types[idx] = "Fuzzy"
    for idx in both:
        duplicate_types[idx] = "Both"

    duplicates_combined = df.loc[list(duplicate_types.keys())].copy()
    duplicates_combined["DuplicateType"] = duplicates_combined.index.map(
        duplicate_types)

    # ---- Display Summary ----
    st.subheader("🔍 Duplicate Detection Summary")
    st.write(f"✅ Exact duplicates: **{len(only_exact)}**")
    st.write(f"🔁 Fuzzy duplicates: **{len(only_fuzzy)}**")
    st.write(f"🔂 Both: **{len(both)}**")
    st.write(f"📊 Total: **{len(duplicates_combined)}** "
             f"({round(len(duplicates_combined)/len(df)*100, 2)}%)")

    if not duplicates_combined.empty:
        st.subheader("🧾 Sample Duplicate Records")
        st.dataframe(duplicates_combined.head(10))

    # # ---- Export Buttons ----
    # def to_csv_download(df, file_name):
    #     buffer = BytesIO()
    #     df.to_csv(buffer, index=False)
    #     return buffer.getvalue()

    # if not duplicates_combined.empty:
    #     st.subheader("⬇️ Download Duplicates")

    #     col1, col2, col3 = st.columns(3)
    #     with col1:
    #         st.download_button("Download Exact", to_csv_download(df.loc[list(only_exact)]), file_name="exact_duplicates.csv")
    #     with col2:
    #         st.download_button("Download Fuzzy", to_csv_download(df.loc[list(only_fuzzy)]), file_name="fuzzy_duplicates.csv")
    #     with col3:
    #         st.download_button("Download Both", to_csv_download(df.loc[list(both)]), file_name="both_duplicates.csv")

        # Header
    st.header("13. Cross-Source Matching")

    # Columns for layout
    csm_col1, csm_col2 = st.columns(2)

    if df1 and df2:
        common_columns = list(set(df1.columns) & set(df2.columns))

        with csm_col1:
            match_columns = st.multiselect(
                "Select matching columns", common_columns, default=common_columns[:2])

        with csm_col2:
            threshold = st.slider("Similarity threshold", 0, 100, 85)

        weights = {}
        for col in match_columns:
            with csm_col1:
                weights[col] = st.slider(f"Weight for '{col}'", 1, 10, 5)

        with csm_col2:
            block_col = st.selectbox("Select a blocking column (optional)", [
                                    None] + common_columns)

        st.subheader("Results")

        def compute_similarity(row1, row2, cols, weights):
            """
            Compute similarity score between two rows based on selected columns and weights.
            
            Parameters:
            row1 (Series): The first row.
            row2 (Series): The second row.
            cols (list): List of columns to compare.
            weights (dict): Weights for each column.

            Returns:
            float: The similarity score.
            """
            score = 0
            total_weight = 0
            for col in cols:
                val1 = str(row1.get(col, '')).strip().lower()
                val2 = str(row2.get(col, '')).strip().lower()
                s = fw.token_sort_ratio(val1, val2)
                score += s * weights[col]
                total_weight += weights[col]
            return round(score / total_weight, 2) if total_weight > 0 else 0

        matches = []
        if block_col:
            df1_blocks = df1.groupby(block_col)
            df2_blocks = df2.groupby(block_col)
            common_keys = set(df1[block_col].dropna()) & set(
                df2[block_col].dropna())
            for key in stqdm(common_keys, desc="Matching Blocks"):
                block1 = df1_blocks.get_group(key)
                block2 = df2_blocks.get_group(key)
                for i1, row1 in block1.iterrows():
                    for i2, row2 in block2.iterrows():
                        sim = compute_similarity(
                            row1, row2, match_columns, weights)
                        if sim >= threshold:
                            matches.append({
                                "DF1_Index": i1,
                                "DF2_Index": i2,
                                "Score": sim,
                                **{f"{col}_1": row1[col] for col in match_columns},
                                **{f"{col}_2": row2[col] for col in match_columns},
                            })
        else:
            for i1, row1 in df1.iterrows():
                for i2, row2 in df2.iterrows():
                    sim = compute_similarity(row1, row2, match_columns, weights)
                    if sim >= threshold:
                        matches.append({
                            "DF1_Index": i1,
                            "DF2_Index": i2,
                            "Score": sim,
                            **{f"{col}_1": row1[col] for col in match_columns},
                            **{f"{col}_2": row2[col] for col in match_columns},
                        })

        # Display results
        if matches:
            results_df = pd.DataFrame(matches).sort_values(
                by="Score", ascending=False)
            st.success(f"✅ Found {len(results_df)} matched pairs")
            st.dataframe(results_df.head(30))
            st.download_button("📥 Download Matched Pairs",
                            results_df.to_csv(index=False), "matched_pairs.csv")
        else:
            st.warning("No matches found based on current configuration.")
    else:
        st.info("Please upload both datasets to enable matching.")
```

```python
# This Python script is a Streamlit application designed for data profiling and analysis.
# It allows users to upload two datasets, perform various data profiling tasks such as 
# column profiling, pattern analysis, duplicate detection, and cross-source matching. 
# The application provides visualizations and metrics to help users understand the 
# structure and quality of their data.

import streamlit as st
import pandas as pd
import numpy as np
import re
import plotly.express as px
import plotly.graph_objects as go
from rapidfuzz import fuzz, process
from fuzzywuzzy import fuzz as fw
from io import BytesIO
from stqdm import stqdm

st.set_page_config(layout="wide", page_title="Data Profiler")
# st.title("📊 Data Profiler")
st.markdown("<h1 style='text-align:center;'>📊 Data Profiler</h1>",
            unsafe_allow_html=True)

# tab_main, tab_explore, tab_duplicates, tab_download = st.tabs([
#     "📁 Upload / Load Data", "🔍 Row/Column Counts", "🔁 Duplicate Detection", "⬇️ Export"
# ])

# with tab_main:
# Step 1: Upload two datasets
dt_1, dt_2 = st.columns(2)
with dt_1:
    st.markdown("<h3 style='text-align:center;'>Dataset 1</h3>",
                unsafe_allow_html=True)
    file1 = st.file_uploader("Upload Dataset 1", type=["csv"], key="file1")
with dt_2:
    st.markdown("<h3 style='text-align:center;'>Dataset 2</h3>",
                unsafe_allow_html=True)
    file2 = st.file_uploader("Upload Dataset 2", type=["csv"], key="file2")

# Step 2: Load both files
df1 = df2 = None
if file1:
    if file1.name.endswith(".csv"):
        df1 = pd.read_csv(file1)
    else:
        df1 = pd.read_excel(file1)

if file2:
    if file2.name.endswith(".csv"):
        df2 = pd.read_csv(file2)
    else:
        df2 = pd.read_excel(file2)

# Step 3: If both are uploaded, let user choose between them
if df1 is not None or df2 is not None:
    dataset_choice = st.radio(
        "Select Dataset to Explore",
        options=["Dataset 1", "Dataset 2"],
        horizontal=True,
        index=0 if df1 is not None else 1
    )

    df = df1 if dataset_choice == "Dataset 1" else df2
    file_name = file1.name if dataset_choice == "Dataset 1" else file2.name
    st.success(
        f"Loaded dataset with {df.shape[0]} records and {df.shape[1]} columns.")

# with tab_explore:
    st.header("1.Record & Column Counts")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    st.subheader("**Sample rows of the data:**")
    st.write(df.dropna().head())
    r_count, c_count = st.columns(2)
    with r_count:
        st.metric("Record Count", f"{df.shape[0]}")
    with c_count:
        st.metric("Column Count", f"{df.shape[1]}")
    # st.write(f"**Record Count:** {df.shape[0]}")
    # st.write(f"**Column Count:** {df.shape[1]}")

    def pattern_percentage(series, pattern):
        """
        Calculate the percentage of values in a pandas Series that match a given regex pattern.

        :param series: pandas Series containing the data to be analyzed.
        :param pattern: Regular expression pattern to match.
        :return: Percentage of values matching the pattern.
        """
        return series.astype(str).str.fullmatch(pattern).mean() * 100

    def text_length(series):
        """
        Calculate the minimum, maximum, and average length of text in a pandas Series.

        :param series: pandas Series containing the text data.
        :return: Tuple containing minimum, maximum, and average text length.
        """
        lengths = series.astype(str).str.len()
        return lengths.min(), lengths.max(), lengths.mean()

    # Function to calculate column profiling data
    st.header('2.Column Profiling')
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()

    def column_profiling(df):
        """
        Perform column profiling on a DataFrame to gather statistics such as data type,
        unique values, null counts, and text lengths.

        :param df: pandas DataFrame to be profiled.
        :return: DataFrame containing profiling data for each column.
        """
        profiling_data = []
        for column in df.columns:
            data_type = df[column].dtype
            unique_values = df[column].nunique()
            uniqueness_percentage = (unique_values / len(df)) * 100
            null_count = df[column].isnull().sum()
            null_percentage = (null_count / len(df)) * 100
            min_length = df[column].astype(str).map(len).min()
            max_length = df[column].astype(str).map(len).max()
            avg_length = df[column].astype(str).map(len).mean()

            # Calculate min, max, mean, median, and std dev only for numeric columns
            if np.issubdtype(df[column].dtype, np.number):
                min_value = df[column].min()
                max_value = df[column].max()
                mean_value = df[column].mean()
                median_value = df[column].median()
                std_dev_value = df[column].std()
            else:
                min_value = None
                max_value = None
                mean_value = None
                median_value = None
                std_dev_value = None

            profiling_data.append({
                'Column Name': column,
                'Data Type': data_type,
                'Unique Values': unique_values,
                'Uniqueness %': uniqueness_percentage,
                'Null Count': null_count,
                'Null %': null_percentage,
                'Min Length': min_length,
                'Max Length': max_length,
                'Avg Length': avg_length,
                'Min Value': min_value,
                'Max Value': max_value,
                'Mean': mean_value,
                'Median': median_value,
                'Std Dev': std_dev_value
            })

        return pd.DataFrame(profiling_data)

    # Calculate column profiling data
    profiling_df = column_profiling(df)

    # Integrate the plots into Streamlit
    st.dataframe(profiling_df)
    # st.plotly_chart(fig1)
    # st.plotly_chart(fig2)

    st.subheader("📊 Column Profiling Visualizations")

    # Filter numeric metrics for fig1
    metrics_to_plot = ['Unique Values', 'Null Count']
    fig1 = go.Figure()
    for metric in metrics_to_plot:
        fig1.add_trace(go.Bar(
            x=profiling_df['Column Name'],
            y=profiling_df[metric],
            name=metric
        ))

    fig1.update_layout(
        barmode='group',
        title='📊 Count & Uniqueness Metrics per Column',
        xaxis_title='Column Name',
        yaxis_title='Count',
        legend_title='Metric',
        height=500
    )

    st.plotly_chart(fig1, use_container_width=True)

    # Create box plot for only numerical profiling metrics (mean, median, std dev)
    distribution_metrics = profiling_df[[
        'Column Name', 'Mean', 'Median', 'Std Dev']].dropna()
    fig2 = go.Figure()
    for metric in ['Mean', 'Median', 'Std Dev']:
        fig2.add_trace(go.Box(
            y=distribution_metrics[metric],
            name=metric,
            boxmean=True
        ))

    fig2.update_layout(
        title='📦 Distribution Metrics (Numeric Columns)',
        xaxis_title='Metrics',
        yaxis_title='Value',
        height=500
    )
    # st.plotly_chart(fig2, use_container_width=True)

    st.header("3.Pattern Analysis")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    pattern_analysis = pd.DataFrame({
        "Column": df.columns,
        "Email %": [pattern_percentage(df[col], r"[^@]+@[^@]+\.[^@]+") for col in df.columns],
        "Phone %": [pattern_percentage(df[col], r"^\+\d{1,3}\s?\d{9,}$") for col in df.columns],
        "Date %": [pd.to_datetime(df[col], errors='coerce').notna().mean() * 100 if df[col].dtype in ['object', 'datetime64'] else 0 for col in df.columns],
        "Numeric %": [pattern_percentage(df[col], r"^\d+(\.\d+)?$") for col in df.columns],
        # "Alphanumeric %": [df[col].astype(str).str.isalnum().mean() * 100 if df[col].dtype == object else 0 for col in df.columns],
        "Alphanumeric %": [df[col].dropna().astype(str).str.isalnum().sum() / len(df[col]) * 100 if df[col].dtype == object else 0 for col in df.columns],
    })
    patt_dict = pattern_analysis.to_dict(orient='records')
    # st.dataframe(pattern_analysis)

    # Create columns dynamically
    # columns = st.columns(len(pattern_analysis), border=True)

    # Get the total number of columns in the DataFrame
    total_columns = len(df.columns)
    cols_per_row = 5

    # Display descriptive text in each column
    for i in range(0, len(patt_dict), cols_per_row):
        cols = st.columns(min(cols_per_row, len(patt_dict) - i), border=True)
        for j, item in enumerate(patt_dict[i:i + cols_per_row]):
            column = item['Column']
            descriptions = []
            if item['Alphanumeric %'] > 0:
                descriptions.append(
                    f"Alphanumeric: {round(item['Alphanumeric %'], 2)}%")
            if item['Numeric %'] > 0:
                descriptions.append(f"Numeric: {round(item['Numeric %'], 2)}%")
            if item['Phone %'] > 0:
                descriptions.append(f"Phone: {round(item['Phone %'], 2)}%")
            if item['Date %'] > 0:
                descriptions.append(f"Date: {round(item['Date %'], 2)}%")
            # if item['Email %'] > 0:
            #     descriptions.append(f"Email: {round(item['Email %'], 2)}%")

            if descriptions:
                cols[j].write(f"**{column}**")
                cols[j].write(" ".join(descriptions))
            else:
                cols[j].write(f"**{column}**")
                cols[j].write("No significant percentage in any category")

    # print(pattern_analysis)
    i = 0
    for item in pattern_analysis[["Column", "Email %"]].to_dict(orient='records'):
        i += 1
        column = item.get('Column')
        email_match = item.get('Email %')
        if email_match > 50:
            st.subheader("Email Patterns")
            counts_table, counts_plot = st.columns(
                2, vertical_alignment='center')
            email_column = column
            email_df = df.copy()
            email_df['Email_Domain'] = email_df[email_column].astype(
                str).str.extract(r'@(.+)$')
            domain_counts = email_df['Email_Domain'].value_counts()
            domain_counts_df = pd.DataFrame(domain_counts)

            fig = px.pie(
                names=domain_counts.index,
                values=domain_counts.values,
                # title='Email Domain Distribution',
                hole=0.3
            )

            with counts_table:
                domain_counts_df
            with counts_plot:
                st.plotly_chart(fig, key=f'{str(i)}_test')

    st.header("4.Top Values per Column")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    df = df.select_dtypes(exclude='bool')
    for col in df.columns:
        i += 1
        st.subheader(f"**{col}**")
        count_df = df[col].dropna().value_counts().head(
        ).rename_axis("Value").reset_index(name="Count")
        tab_col, plot_col = st.columns(2, vertical_alignment='center')
        with tab_col:
            st.dataframe(count_df)
        fig = px.histogram(
            data_frame=count_df,
            y="Count",
            x="Value"
        )
        fig.update_xaxes(type='category')
        with plot_col:
            st.plotly_chart(fig, key=f'{str(i)}_test')

    st.header("5.Null % by Column")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    null_tab, null_plot = st.columns(2, vertical_alignment='center')
    null_percentages = df.isnull().mean() * 100
    with null_tab:
        st.dataframe(null_percentages.reset_index().rename(
            columns={"index": "Column", 0: "Null %"}))
    null_percent_df = null_percentages.to_frame(name="Percent")
    fig = px.bar(
        data_frame=null_percent_df,
        x=null_percent_df.index,
        y="Percent",
        range_y=[0, 100]
    )
    with null_plot:
        st.plotly_chart(fig)

    st.header("6.Table Summary")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    completeness = 100 - df.isnull().stack().mean() * 100
    validity = pattern_analysis[['Email %', 'Phone %', 'Date %']].mean().mean()
    uniqueness = df.nunique().mean() / len(df) * 100
    consistency = pattern_analysis[['Alphanumeric %']].mean().mean()
    overall_score = np.mean([completeness, validity, uniqueness, consistency])

    # Create columns
    col0, col1, col2, col3, col4, col5 = st.columns(6)

    # Display metrics in columns
    with col0:
        st.metric("Source", f"{file_name}")
    with col1:
        st.metric("Completeness", f"{completeness:.2f}%")
    with col2:
        st.metric("Validity", f"{validity:.2f}%")
    with col3:
        st.metric("Uniqueness", f"{uniqueness:.2f}%")
    with col4:
        st.metric("Consistency", f"{consistency:.2f}%")
    with col5:
        st.metric("Overall Score", f"{overall_score:.2f}%")

    st.header("7.Column-wise Summary")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    quality_scores = []
    for col in df.columns:
        non_null = df[col].notnull().mean() * 100
        if df[col].dtype == object and col.lower() == "email":
            valid = pattern_percentage(df[col], r"[^@]+@[^@]+\.[^@]+")
        elif df[col].dtype == object and "phone" in col.lower():
            valid = pattern_percentage(df[col], r"\d{10}")
        elif np.issubdtype(df[col].dtype, np.datetime64):
            valid = df[col].notnull().mean() * 100
        else:
            valid = 100
        unique = df[col].nunique() / len(df) * 100
        consistent = df[col].astype(str).str.isalnum(
        ).mean() * 100 if df[col].dtype == object else 100
        quality_scores.append({
            "Column": col,
            "Completeness %": non_null,
            "Validity %": valid,
            "Uniqueness %": unique,
            "Consistency %": consistent
        })
    st.dataframe(pd.DataFrame(quality_scores))

    st.header("8.Primary Key Identification")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    potential_keys = []
    for col in df.columns:
        if df[col].is_unique and df[col].notnull().all():
            potential_keys.append(col)
    if potential_keys:
        st.success(f"Potential Primary Key(s): {', '.join(potential_keys)}")
    else:
        st.warning("No single-column primary key found.")

    st.header("9. Picklist Value Extraction (Categoricals)")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    # pick_cols = st.columns(sum(1 for col in df.columns if df[col].dtype == object))
    # _i = 0
    # for col in df.columns:
    #     if df[col].dtype == object:# and df[col].nunique() < 20:
    #         with pick_cols[_i]:
    #             st.markdown(f"**{col}** (Picklist values: {df[col].nunique()})")
    #             st.dataframe(df[col].value_counts().rename_axis(
    #                 "Value").reset_index(name="Count"))
    #         _i += 1

    # Define the maximum number of columns per row
    max_columns_per_row = 5

    # Create rows of columns dynamically
    object_columns = [col for col in df.columns if df[col].dtype == object]
    total_columns = len(object_columns)

    for i in range(0, total_columns, max_columns_per_row):
        cols = st.columns(min(max_columns_per_row, total_columns - i))
        for j in range(min(max_columns_per_row, total_columns - i)):
            col_index = i + j
            col = object_columns[col_index]
            with cols[j]:
                st.markdown(
                    f"**{col}** (Picklist values: {df[col].nunique()})")
                st.dataframe(df[col].value_counts().rename_axis(
                    "Value").reset_index(name="Count"))

    st.header("10. Suggested Match & Merge Rules")
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    match_rules = []
    for col in df.columns:
        if col.lower() in ["email", "id", "phone"]:
            match_type = "ExactMatch"
        elif df[col].dtype == object and df[col].str.len().mean() > 10:
            match_type = "FuzzyMatch"
        elif df[col].dtype == object:
            match_type = "CompositeMatch"
        else:
            match_type = "ExactMatch"
        match_rules.append({"Column": col, "Suggested Match Rule": match_type})
    st.dataframe(pd.DataFrame(match_rules))

    st.header("11. Survivorship Rules (Suggestions)")

    def calculate_survivorship_df(df, status_column="status", active_value="active"):
        """
        Calculate the survivorship rate based on a status column and an active value.

        :param df: pandas DataFrame to be analyzed.
        :param status_column: Column name indicating the status of records.
        :param active_value: Value in the status column that signifies an active record.
        :return: Percentage of surviving records.
        """
        if status_column not in df.columns:
            return 0.0  # If column doesn't exist
        total_records = len(df)
        if total_records == 0:
            return 0.0
        surviving_records = df[status_column].str.lower().eq(
            active_value).sum()
        return (surviving_records / total_records) * 100

    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()
    # surv_rules = []
    # for col in df.columns:
    #     if "date" in col.lower():
    #         rule = "Most Recent"
    #     elif df[col].dtype == object:
    #         rule = "Longest Text"
    #     elif df[col].dtype in [int, float]:
    #         rule = "Max Value"
    #     else:
    #         rule = "Most Frequent"
    #     surv_rules.append({"Column": col, "Survivorship Rule": rule})
    # st.dataframe(pd.DataFrame(surv_rules))
    # Survivorship Rate from DataFrame
    # survivorship_rate = calculate_survivorship_df(df, status_column="status", active_value="active")

    st.subheader("Survivorship Rate")
    # st.metric(label="Rate of Active Records", value=f"{survivorship_rate:.2f}%")

    if not df.empty:
        col1, col2 = st.columns(2)

        with col1:
            # Select column to use for survivorship status
            status_col = st.selectbox(
                "Select Status Column", df.columns, key="status_col")

        with col2:
            # Select active value that signifies a "surviving" record
            if status_col:
                unique_values = df[status_col].dropna().unique()
                active_value = st.selectbox(
                    "Select Active Value", unique_values, key="active_value")

        # Function to calculate survivorship rate
        def calculate_survivorship(df, status_col, active_value):
            """
            Calculate the survivorship rate based on a status column and an active value.

            :param df: pandas DataFrame to be analyzed.
            :param status_col: Column name indicating the status of records.
            :param active_value: Value in the status column that signifies an active record.
            :return: Percentage of surviving records.
            """
            total_records = len(df)
            surviving_records = df[status_col].eq(active_value).sum()
            if total_records == 0:
                return 0
            return (surviving_records / total_records) * 100

        # Calculate and display the rate
        survivorship_rate = calculate_survivorship(
            df, status_col, active_value)
        st.metric("Survivorship Rate", f"{survivorship_rate:.2f}%")

    st.header("12.Duplicate Detection")
    # df = df1.copy() if dataset_dup_detec == "Dataset 1" else df2.copy()
    # duplicates = df[df.duplicated()]
    # st.write(f"🔍 Found {len(duplicates)} duplicate records.")
    # st.write(f"🔍 Found {round(len(duplicates)/len(df)*100, ndigits=2)} percent of duplicate records.")
    # if not duplicates.empty:
    #     st.dataframe(duplicates.head(10))
    # ---- Load Data ----
    df = df1.copy() if dataset_choice == "Dataset 1" else df2.copy()

    # ---- Streamlit UI for Fuzzy Matching Columns ----
    all_categorical = df.select_dtypes(include='object').columns.tolist()
    # ['ID', 'UniqueID']
    exclude_cols = [
        col for col in all_categorical if df[col].nunique() == len(df)]
    default_cols = [col for col in all_categorical if col not in exclude_cols]

    dd_col1, dd_col2 = st.columns(2)
    with dd_col1:
        fuzzy_columns = st.multiselect(
            "Select columns for fuzzy matching", options=all_categorical, default=default_cols)
    with dd_col2:
        threshold = st.slider("Fuzzy match threshold",
                              min_value=50, max_value=100, value=90, step=5)

    # ---- Exact Duplicate Detection ----
    exact_dupes = df[df.duplicated(keep=False)].copy()
    exact_dupe_indices = set(exact_dupes.index)

    # ---- Fuzzy Duplicate Detection (with blocking optimization) ----
    matched_indices = set()
    if fuzzy_columns:
        # Create a blocking key (e.g., first character of name or phone)
        df['__fuzzy_key__'] = df[fuzzy_columns].fillna(
            '').agg(' '.join, axis=1)
        df['__block_key__'] = df[fuzzy_columns[0]].str[0].fillna('')

        for _, block_df in df.groupby('__block_key__'):
            keys = block_df['__fuzzy_key__'].tolist()
            indices = block_df.index.tolist()

            for i in range(len(keys)):
                if indices[i] in matched_indices:
                    continue
                matches = process.extract(
                    keys[i], keys, scorer=fuzz.token_sort_ratio, limit=None)
                for match_text, score, match_idx in matches:
                    idx_j = indices[match_idx]
                    if score >= threshold and indices[i] != idx_j:
                        matched_indices.add(indices[i])
                        matched_indices.add(idx_j)

        fuzzy_dupe_indices = matched_indices
        df.drop(columns=['__fuzzy_key__', '__block_key__'], inplace=True)
    else:
        fuzzy_dupe_indices = set()

    fuzzy_dupes = df.loc[list(fuzzy_dupe_indices)].copy()

    # ---- Classify Duplicates by Type ----
    only_exact = exact_dupe_indices - fuzzy_dupe_indices
    only_fuzzy = fuzzy_dupe_indices - exact_dupe_indices
    both = exact_dupe_indices & fuzzy_dupe_indices

    # Map duplicate types
    duplicate_types = {}
    for idx in only_exact:
        duplicate_types[idx] = "Exact"
    for idx in only_fuzzy:
        duplicate_types[idx] = "Fuzzy"
    for idx in both:
        duplicate_types[idx] = "Both"

    duplicates_combined = df.loc[list(duplicate_types.keys())].copy()
    duplicates_combined["DuplicateType"] = duplicates_combined.index.map(
        duplicate_types)

    # ---- Display Summary ----
    st.subheader("🔍 Duplicate Detection Summary")
    st.write(f"✅ Exact duplicates: **{len(only_exact)}**")
    st.write(f"🔁 Fuzzy duplicates: **{len(only_fuzzy)}**")
    st.write(f"🔂 Both: **{len(both)}**")
    st.write(f"📊 Total: **{len(duplicates_combined)}** "
             f"({round(len(duplicates_combined)/len(df)*100, 2)}%)")

    if not duplicates_combined.empty:
        st.subheader("🧾 Sample Duplicate Records")
        st.dataframe(duplicates_combined.head(10))

    # # ---- Export Buttons ----
    # def to_csv_download(df, file_name):
    #     buffer = BytesIO()
    #     df.to_csv(buffer, index=False)
    #     return buffer.getvalue()

    # if not duplicates_combined.empty:
    #     st.subheader("⬇️ Download Duplicates")

    #     col1, col2, col3 = st.columns(3)
    #     with col1:
    #         st.download_button("Download Exact", to_csv_download(df.loc[list(only_exact)]), file_name="exact_duplicates.csv")
    #     with col2:
    #         st.download_button("Download Fuzzy", to_csv_download(df.loc[list(only_fuzzy)]), file_name="fuzzy_duplicates.csv")
    #     with col3:
    #         st.download_button("Download Both", to_csv_download(df.loc[list(both)]), file_name="both_duplicates.csv")

        # Header
    st.header("13. Cross-Source Matching")

    # Columns for layout
    csm_col1, csm_col2 = st.columns(2)

    if df1 and df2:
        common_columns = list(set(df1.columns) & set(df2.columns))

        with csm_col1:
            match_columns = st.multiselect(
                "Select matching columns", common_columns, default=common_columns[:2])

        with csm_col2:
            threshold = st.slider("Similarity threshold", 0, 100, 85)

        weights = {}
        for col in match_columns:
            with csm_col1:
                weights[col] = st.slider(f"Weight for '{col}'", 1, 10, 5)

        with csm_col2:
            block_col = st.selectbox("Select a blocking column (optional)", [
                                    None] + common_columns)

        st.subheader("Results")

        def compute_similarity(row1, row2, cols, weights):
            """
            Compute similarity score between two rows based on selected columns and weights.

            :param row1: First row (Series) to compare.
            :param row2: Second row (Series) to compare.
            :param cols: List of columns to use for comparison.
            :param weights: Dictionary of weights for each column.
            :return: Similarity score as a float.
            """
            score = 0
            total_weight = 0
            for col in cols:
                val1 = str(row1.get(col, '')).strip().lower()
                val2 = str(row2.get(col, '')).strip().lower()
                s = fw.token_sort_ratio(val1, val2)
                score += s * weights[col]
                total_weight += weights[col]
            return round(score / total_weight, 2) if total_weight > 0 else 0

        matches = []
        if block_col:
            df1_blocks = df1.groupby(block_col)
            df2_blocks = df2.groupby(block_col)
            common_keys = set(df1[block_col].dropna()) & set(
                df2[block_col].dropna())
            for key in stqdm(common_keys, desc="Matching Blocks"):
                block1 = df1_blocks.get_group(key)
                block2 = df2_blocks.get_group(key)
                for i1, row1 in block1.iterrows():
                    for i2, row2 in block2.iterrows():
                        sim = compute_similarity(
                            row1, row2, match_columns, weights)
                        if sim >= threshold:
                            matches.append({
                                "DF1_Index": i1,
                                "DF2_Index": i2,
                                "Score": sim,
                                **{f"{col}_1": row1[col] for col in match_columns},
                                **{f"{col}_2": row2[col] for col in match_columns},
                            })
        else:
            for i1, row1 in df1.iterrows():
                for i2, row2 in df2.iterrows():
                    sim = compute_similarity(row1, row2, match_columns, weights)
                    if sim >= threshold:
                        matches.append({
                            "DF1_Index": i1,
                            "DF2_Index": i2,
                            "Score": sim,
                            **{f"{col}_1": row1[col] for col in match_columns},
                            **{f"{col}_2": row2[col] for col in match_columns},
                        })

        # Display results
        if matches:
            results_df = pd.DataFrame(matches).sort_values(
                by="Score", ascending=False)
            st.success(f"✅ Found {len(results_df)} matched pairs")
            st.dataframe(results_df.head(30))
            st.download_button("📥 Download Matched Pairs",
                            results_df.to_csv(index=False), "matched_pairs.csv")
        else:
            st.warning("No matches found based on current configuration.")
    else:
        st.info("Please upload both datasets to enable matching.")
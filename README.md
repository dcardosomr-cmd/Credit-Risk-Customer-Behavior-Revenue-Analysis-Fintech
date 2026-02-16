# Credit Risk, Customer Behavior & Revenue Analysis - Fintech

## 📊 Project Overview

This project presents a comprehensive analysis of credit risk, customer behavior, and revenue performance for a fintech lender. It integrates multiple Power BI dashboards to monitor application volumes, requested amounts, and approval rates over time, segmented by credit score, age group, and loan purpose, as well as operational metrics such as days to approval.

Transaction-level data is used to quantify refunds and fraud across merchant categories, countries, and channels, highlighting a high refund rate alongside consistently low fraud, which suggests process and UX improvement opportunities rather than security gaps. User activity and funnel data further reveal device usage patterns, engagement by day of week, and conversion drop-offs, informing targeted marketing and product optimizations.

---

## 🎯 Project Objectives

- **Credit Risk Assessment**: Analyze credit application patterns, approval rates by credit score bands, and identify high-value customer segments
- **Customer Behavior Analysis**: Track user engagement, session duration, device usage, and funnel conversion metrics
- **Revenue Performance**: Monitor transaction volumes, refund rates, fraud detection, and revenue trends across merchant categories
- **Operational Efficiency**: Measure approval process timelines and identify bottlenecks

---

## 🔑 Key Findings

### Credit Applications & Approvals

- **Overall Approval Rate**: 68.4% across all applications
- **Credit Score Impact**: Approval rates range from 53.4% (score <600) to 89.6% (score 850+)
- **High-Value Segment**: Customers aged 25-34 with credit scores 763+ show the strongest approval rates (81.4%-89.6%) and higher average loan amounts
- **Loan Purpose**: Personal and home loans demonstrate higher approval rates and larger requested amounts
- **Quarterly Trends**: Application volumes show seasonal patterns with peaks in Q4

### Transaction Analysis

- **Refund Rate**: Approximately 20% overall refund rate across all transactions
- **High-Risk Categories**: Entertainment and healthcare merchant categories show elevated refund rates
- **Fraud Rate**: Consistently low at ~1%, indicating strong fraud detection systems
- **Key Insight**: High refund rate with low fraud suggests operational or UX/human-error issues rather than security gaps

### Customer Engagement

- **Device Usage**: Mobile vs web engagement patterns identified
- **Weekly Patterns**: Clear engagement trends by day of week
- **Conversion Funnel**: Drop-off points identified between app open and order confirmation
- **Session Duration**: Analyzed by device type to inform UX optimization

---

## 📈 Dashboards

### 1. Credit Applications Dashboard

**Purpose**: Track credit application volumes, requested amounts, and trends over time

**Key Metrics**:
- Total applications by quarter
- Average requested amount
- Application distribution by loan purpose
- Age group analysis with income levels

**Insights**:
- Q4 shows peak application volumes
- Personal and home loans drive the highest requested amounts
- 25-34 age group represents the most active segment

### 2. Credit Approvals Dashboard

**Purpose**: Analyze approval rates, credit quality, and operational efficiency

**Key Metrics**:
- Approval rate by credit score bands (with conditional formatting)
- Days to approval by quarter and loan purpose
- Approval percentage trends
- Income and requested amount by age group

**Insights**:
- Credit scores 763+ show approval rates >80% (target segment)
- Approval processing times vary by loan purpose
- Clear correlation between credit score bands and approval likelihood

**DAX Measures**:
```dax
// Approval Rate
a% = DIVIDE(
    CALCULATE( COUNTROWS( credit_applications ), credit_applications[is_approved] = TRUE() ),
    COUNTROWS( credit_applications ),
    0
)

// Approval % (0-100) for conditional formatting
Approval % (0-100) = [a%] * 100
```

### 3. Transactions Dashboard

**Purpose**: Monitor transaction volumes, refunds, fraud, and revenue distribution

**Key Metrics**:
- Total transactions and amounts
- Refund rate by merchant category and year
- Fraud detection metrics
- Distribution by country, channel, and account type

**Insights**:
- 20% refund rate concentrated in specific merchant categories
- <1% fraud rate indicates effective fraud prevention
- Transaction distribution varies significantly by country and channel

**DAX Measures**:
```dax
// Refund Rate
Refund % = 
DIVIDE(
    CALCULATE( 
        COUNT( transactions_fintech[transaction_id] ), 
        transactions_fintech[transaction_type] = "refund"
    ),
    COUNT( transactions_fintech[transaction_id] ),
    0
)

// Total Transactions
Total Transactions := COUNTROWS( 'transactions_fintech' )

// Refund Transactions
Refund Transactions := 
CALCULATE (
    [Total Transactions],
    'transactions_fintech'[transaction_type] = "refund"
)
```

### 4. Customer Analysis Dashboard

**Purpose**: Understand user engagement, behavior patterns, and conversion funnels

**Key Metrics**:
- Session duration by device
- Event types and frequency
- Weekly engagement patterns
- Conversion funnel analysis

**Insights**:
- Device preferences inform UX design priorities
- Clear weekly engagement patterns support marketing timing
- Identified conversion drop-off points for optimization

---

## 💡 Recommendations

### 1. Target High-Value Segments
- **Action**: Focus marketing and product offerings on customers aged 25-34 with credit scores 763+
- **Expected Impact**: Higher approval rates (>80%) and larger loan amounts
- **Implementation**: Develop targeted campaigns for this demographic with streamlined application processes

### 2. Reduce Refund Rates
- **Action**: Investigate entertainment and healthcare merchant categories for process improvements
- **Expected Impact**: Reduce overall 20% refund rate through better UX and error prevention
- **Implementation**: 
  - Review transaction flows in high-refund categories
  - Implement additional confirmation steps
  - Improve user education and guidance

### 3. Optimize Approval Process
- **Action**: Standardize approval timelines across loan purposes
- **Expected Impact**: Improved customer satisfaction and operational efficiency
- **Implementation**: Analyze longest processing times by loan purpose and streamline workflows

### 4. Seasonal Campaign Planning
- **Action**: Leverage Q4 peak application periods with targeted campaigns
- **Expected Impact**: Maximize conversion during high-intent periods
- **Implementation**: Prepare marketing materials and ensure adequate operational capacity

### 5. UX Improvements
- **Action**: Address conversion funnel drop-offs identified between app open and order confirmation
- **Expected Impact**: Increased completion rates and revenue
- **Implementation**: 
  - A/B test simplified flows
  - Optimize for mobile experience based on device usage patterns
  - Implement progress indicators and help features

---

## 🛠️ Technical Details

### Tools & Technologies
- **Power BI Desktop**: Dashboard development and data visualization
- **DAX (Data Analysis Expressions)**: Custom measures and calculated columns
- **Power Query (M)**: Data transformation and cleansing
- **SQL**: Data analysis and query development

### Data Sources
- `credit_applications.csv`: Credit application data with demographics, loan details, and approval status
- `transactions_fintech.csv`: Transaction-level data including amounts, types, merchant categories, and fraud flags
- `user_events.csv`: User activity and engagement data
- `users_cohort.csv`: User demographic and account information

### Key Transformations

**Power Query (M)**:
```m
// Create Approval Status column
Approval Status = 
if [is_approved] = true then
    "Approved"
else
    "Not approved"

// Extract Year from timestamp
Year = Year([timestamp])
```

**DAX Calculated Columns**:
```dax
// Approval Status (alternative method)
Approval Status =
IF (
    'credit_applications'[is_approved] = TRUE(),
    "Approved",
    "Not approved"
)

// Year from transaction timestamp
Year = YEAR ( 'transactions_fintech'[timestamp] )
```

### Analysis Approach

1. **Exploratory Data Analysis**: Initial data profiling and quality assessment
2. **Segmentation Analysis**: Credit score banding, age groups, loan purposes
3. **Time-Series Analysis**: Quarterly trends and seasonal patterns
4. **Cohort Analysis**: Customer behavior by signup date and demographics
5. **Funnel Analysis**: User journey from signup to transaction completion
6. **Risk Assessment**: Approval rates, refund patterns, and fraud detection

---

## 📊 Visual Design Principles

- **Consistent Color Scheme**: Professional fintech theme throughout all dashboards
- **Conditional Formatting**: Color-coded approval rates for quick insights (Red <60%, Yellow 60-80%, Green >80%)
- **Interactive Filters**: Year, quarter, and demographic slicers for dynamic exploration
- **KPI Cards**: Clear display of key metrics at the top of each dashboard
- **Reference Lines**: 20% refund rate benchmark and other thresholds for context

---

## 🎓 Skills Demonstrated

- **Data Analysis**: Statistical analysis, segmentation, trend identification
- **Data Visualization**: Dashboard design, visual selection, storytelling with data
- **Business Intelligence**: KPI development, metric definition, business insights
- **DAX Programming**: Complex measures, calculated columns, time intelligence
- **Power Query**: Data transformation, cleaning, and modeling
- **SQL**: Query optimization, joins, window functions, aggregations
- **Business Acumen**: Credit risk assessment, financial metrics, customer analytics
- **Problem Solving**: Root cause analysis, recommendation development

---

## 🔍 Future Enhancements

1. **Predictive Modeling**: Build credit risk scoring models using machine learning
2. **Customer Lifetime Value**: Calculate and predict CLV by segment
3. **Churn Analysis**: Identify at-risk customers and implement retention strategies
4. **Real-Time Dashboards**: Implement live data connections for up-to-the-minute insights
5. **Advanced Fraud Detection**: Develop sophisticated fraud scoring algorithms
6. **A/B Testing Framework**: Systematically test process improvements and measure impact

---

## 📝 Project Structure

```
Credit-Risk-Customer-Behavior-Revenue-Analysis-Fintech/
│
├── README.md                          # Project documentation (this file)
├── dashboards/
│   └── Fintech_Analytics.pbix        # Power BI dashboard file
├── data/
│   ├── credit_applications.csv       # Credit application data
│   ├── transactions_fintech.csv      # Transaction data
│   ├── user_events.csv              # User activity data
│   └── users_cohort.csv             # User demographic data
├── sql/
│   ├── exploratory_analysis.sql     # Initial data exploration queries
│   ├── credit_analysis.sql          # Credit risk analysis queries
│   └── user_journey_analysis.sql    # Customer behavior queries
└── images/
    ├── applications_dashboard.png   # Dashboard screenshots
    ├── approvals_dashboard.png
    ├── transactions_dashboard.png
    └── customer_dashboard.png
```

---

## 📧 Contact

**Author**: Data Analyst transitioning from Marketing
**Location**: Lisbon, Portugal
**Skills**: Power BI | SQL | Python | DAX | Data Visualization

---

## 📄 License

This project is part of a personal data analytics portfolio.

---

## 🙏 Acknowledgments

- Dataset inspiration from fintech industry use cases
- Analysis methodology informed by credit risk and customer analytics best practices
- Dashboard design principles from Power BI community and professional standards

<div align="center">

# 🏥 Access to Care
### Opioid Overdose Risk & Treatment Availability Across U.S. Counties

*A data science capstone project analyzing opioid mortality, treatment access, and socioeconomic risk across 1,887 U.S. counties from 2018–2024.*

[![Live Dashboard](https://img.shields.io/badge/▶%20Live%20Dashboard-shinyapps.io-1B2A4A?style=for-the-badge)](your-shinyapps-url-here)

---

[![R Shiny](https://img.shields.io/badge/R-Shiny-276DC3?style=flat-square&logo=r&logoColor=white)](https://shiny.posit.co/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![CDC WONDER](https://img.shields.io/badge/Data-CDC%20WONDER-005A8E?style=flat-square)](https://wonder.cdc.gov/)
[![SAMHSA](https://img.shields.io/badge/Data-SAMHSA-E8A020?style=flat-square)](https://findtreatment.gov/)

</div>

---

## 📌 At a Glance

<div align="center">

| 🗺️ 1,887 Counties | 📅 2018–2024 | 🔬 4 Research Questions | 📊 4 Data Sources |
|:---:|:---:|:---:|:---:|
| Analyzed nationwide | 7-year study period | Answered with statistics | CDC · Census · SAMHSA · USDA |

</div>

---

## 🔍 Key Findings

> **TL;DR:** Poverty and unemployment predict overdose risk. Facilities are misallocated. Rural counties face compounded disadvantage. Appalachian counties are the most underserved in the nation.

<br>

**Q1 — Socioeconomic factors correlate with overdose mortality**
- Poverty rate: **r = +0.29** · Unemployment rate: **r = +0.23** · Median income: **r = −0.24**
- All significant at **p < 0.001** across 1,887 counties

**Q2 — Facilities are NOT distributed in proportion to need**
- **462 counties** are simultaneously High Risk & Low Access
- Facility placement follows population density, not overdose burden — the distribution is nearly random relative to need

**Q3 — Rural counties face independent disadvantage**
- After controlling for income, poverty, and unemployment via USDA RUCC codes, rurality independently predicts higher overdose mortality
- **RUCC coefficient = −33.4** (p < 0.001) · R² improved **0.118 → 0.170**

**Q4 — The access gap is nationwide and severe**
- **Every U.S. state** has a positive gap (overdose burden exceeds treatment supply)
- **McDowell County, WV** leads the composite risk index at **91.9 / 100**
- West Virginia and Kentucky account for **14 of the top 25** most at-risk counties

---

## 🖥️ Dashboard Features

The interactive Shiny dashboard lets anyone explore these findings without running code.

| Feature | Description |
|---|---|
| 🗺️ **Choropleth Map** | 9 selectable metrics — including RUCC urban-rural classification. Click any county for a full data popup. |
| 🔍 **Dual Filters** | Filter by state AND urban-rural type (Metro / Non-metro / Rural) simultaneously. |
| ⚠️ **At-Risk Table** | Composite risk score rankings with a user-controlled slider (5–100 counties). |
| 📊 **County Rankings** | Top 20 bar chart for any selected metric, updated dynamically by filters. |
| 🔢 **Live Value Boxes** | Real-time summaries including "Rural Counties: High Risk & Low Access" count. |
| 📋 **Full Data Table** | Complete county dataset with RUCC codes — sortable, searchable, exportable. |

---

## 🚀 How to Run

### 1 · Python Analysis

> **Requires:** Python 3.10+

```bash
pip install pandas numpy matplotlib seaborn scipy statsmodels scikit-learn requests openpyxl
```

Run the notebooks **in order:**

```
1. API_Socioeconomic_Data_Pull.ipynb   →  Pull Census ACS data
2. cleaning_data_2024.ipynb            →  Clean CDC WONDER mortality data
3. Merging_Cleaning_Data.ipynb         →  Build master dataset + merge USDA RUCC codes
4. analysis.ipynb                      →  Run all 4 research questions, generate charts
```

> ℹ️ `Merging_Cleaning_Data.ipynb` downloads USDA RUCC data automatically. Internet access required.

---

### 2 · R Shiny Dashboard

> **Requires:** R 4.2+

```r
install.packages(c(
  "shiny", "shinydashboard", "shinyjs",
  "leaflet", "sf", "dplyr", "readr",
  "tigris", "stringr", "plotly", "DT", "viridis"
))
```

**Before running the app**, generate the pre-built map file:

```r
source("build_map_data.R")   # run once locally — creates map_data.rds
```

Then launch:

```r
shiny::runApp("shiny/")
```

**To deploy to shinyapps.io**, include these four files:

```
app.R  ·  server.R  ·  ui.R  ·  map_data.rds
```

---

## 🗂️ Project Structure

```
access-to-care-capstone-project/
│
├── 📂 data/
│   ├── master_df.csv                     # Base merged dataset
│   └── master_df_rucc.csv               # Enriched with USDA RUCC codes
│
├── 📂 notebooks/
│   ├── API_Socioeconomic_Data_Pull.ipynb # Census ACS data collection
│   ├── cleaning_data_2024.ipynb          # CDC WONDER cleaning
│   ├── Merging_Cleaning_Data.ipynb       # Master dataset + RUCC merge
│   └── analysis.ipynb                    # Full analysis — all 4 research questions
│
├── 📂 shiny/
│   ├── app.R                             # App launcher
│   ├── server.R                          # Server logic
│   ├── ui.R                             # UI layout
│   ├── build_map_data.R                 # Pre-build map_data.rds (run before deploying)
│   └── map_data.rds                     # Pre-merged, simplified shapefile (generated)
│
├── 📂 outputs/                           # Generated charts
│   ├── q1_correlation_heatmap.png
│   ├── q1_socioeconomic_scatter.png
│   ├── q2_facility_vs_overdose.png
│   ├── q2_quadrant_chart.png
│   ├── q3_access_boxplot.png
│   ├── q3_regression_coefs.png
│   ├── q3_rucc_rates.png
│   ├── q3_rucc_regression_comparison.png
│   ├── q3_urban_rural_scatter.png
│   ├── q4_gap_distribution.png
│   ├── q4_state_gap.png
│   └── q4_top25_risk.png
│
└── README.md
```

---

## 📦 Data Sources

| Source | What it provides | Coverage |
|---|---|---|
| [CDC WONDER](https://wonder.cdc.gov/) | Age-adjusted opioid overdose mortality rates per 100k by county. Counties with <10 deaths are suppressed. | 2018–2024 |
| [U.S. Census Bureau ACS](https://www.census.gov/programs-surveys/acs) | Median household income, poverty rate, unemployment rate, population | 5-year estimates |
| [SAMHSA Treatment Locator](https://findtreatment.gov/) | Substance abuse treatment facility locations — used to compute facility counts and rates per 100k | Current |
| [USDA Rural-Urban Continuum Codes](https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/) | 9-category urban-rural classification (1 = largest metro, 9 = most remote rural) | 2023 |

---

## 📐 Metric Definitions

| Metric | Formula | What it measures |
|---|---|---|
| **Overdose Rate** | Deaths ÷ Population × 100,000 | Age-adjusted opioid deaths per 100k person-years, 2018–2024 |
| **Facility Rate** | Facilities ÷ Population × 100,000 | Treatment supply per 100k residents |
| **Gap Score** | Overdose Rate − Facility Rate | Unmet need — how much mortality burden exceeds treatment supply |
| **Composite Risk Score** | (norm overdose + norm poverty + norm low facilities) ÷ 3 × 100 | Equal-weighted risk index scaled 0–100 |
| **RUCC** | USDA classification 1–9 | 1 = metro >1M population · 9 = completely rural and remote |

> 💡 **Gap Score in plain English:** *"How many more people are dying per 100,000 than there are facilities to treat them."* The median U.S. county gap is **161.4** — and every county is positive.

---

## ⚠️ Limitations

- **CDC suppression** — Counties with <10 opioid deaths have missing mortality data, likely underrepresenting rural low-mortality areas and understating rural risk.
- **Correlational only** — All findings are observational. Unmeasured confounders (drug supply, state policy, cultural factors) explain remaining variance. No causal claims are made.
- **Facility presence ≠ access** — SAMHSA data captures whether a facility exists, not its capacity, cost, wait times, or whether patients can realistically receive care.
- **Time alignment** — ACS 5-year estimates may not perfectly align with the 2018–2024 mortality observation window.

---

## 🔭 Future Directions

- **Drug supply data** — Incorporate DEA fentanyl seizure data by county to separate supply-side from demand-side drivers
- **State policy variables** — Add naloxone access laws, Medicaid expansion status, and opioid prescribing regulations as covariates
- **Longitudinal analysis** — Track how counties move across risk quadrants over time as policy and facility access evolve
- **Capacity-adjusted access** — Replace raw facility count with capacity-weighted or utilization-based measures for a truer access metric

---

## 👤 Author

**Josh Tacker** · Data Science Capstone Project · 2026

---

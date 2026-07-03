# Access to Care: Opioid Overdose Risk & Treatment Availability Across U.S. Counties

[![R](https://img.shields.io/badge/R-Shiny-276DC3?logo=r)](https://shiny.posit.co/)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Data: CDC WONDER](https://img.shields.io/badge/Data-CDC%20WONDER-005A8E)](https://wonder.cdc.gov/)

An interactive geospatial analysis of opioid overdose mortality, treatment access, and socioeconomic risk across **1,887 U.S. counties** from **2018–2024**, built as a data science capstone project.

**[▶ Live Dashboard](https://joshwtacker.shinyapps.io/access_to_care_us_counties/)**

---

## 📊 Key Findings

| Research Question | Finding |
|---|---|
| **Q1: Socioeconomic factors** | Poverty (r = +0.29) and unemployment (r = +0.23) positively correlate with overdose mortality; income is protective (r = −0.24). All p < 0.001. |
| **Q2: Facility distribution** | 462 counties are High Risk & Low Access. Facilities follow population density, not overdose burden — the distribution is nearly random relative to need. |
| **Q3: Does access help?** | After controlling for urbanicity (RUCC), rural counties face significantly higher overdose mortality independent of socioeconomic factors (RUCC coef = −33.4, p < 0.001). R² improved from 0.118 → 0.170. |
| **Q4: Gap counties** | Every U.S. state has a positive access gap. McDowell County, WV scores 91.9/100 on the composite risk index. West Virginia and Kentucky together account for 14 of the top 25 most at-risk counties. |

---

## 🗂 Project Structure

```
access-to-care-capstone-project/
│
├── data/
│   ├── cleaned/
│   │   ├── cdc_cleaned_2024.csv          # CDC WONDER opioid mortality data
│   │   ├── samhsa_facilities_zip.csv     # SAMHSA treatment facility locations
│   │   └── census_acs_2024.csv          # ACS socioeconomic estimates
│   ├── master_df.csv                     # Base merged dataset
│   └── master_df_rucc.csv               # Enriched with USDA RUCC codes
│
├── notebooks/
│   ├── API_Socioeconomic_Data_Pull.ipynb # Census ACS data collection
│   ├── cleaning_data_2024.ipynb          # CDC WONDER data cleaning
│   ├── Merging_Cleaning_Data.ipynb       # Master dataset construction + RUCC merge
│   └── analysis.ipynb                    # Full analysis — all 4 research questions
│
├── shiny/
│   ├── app.R                             # App launcher
│   ├── server.R                          # Server logic
│   └── ui.R                             # UI layout
│
├── outputs/                              # Generated charts (gitignored if large)
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

## 🚀 How to Run

### Python Analysis (Jupyter Notebooks)

**Requirements:** Python 3.10+

```bash
pip install pandas numpy matplotlib seaborn scipy statsmodels scikit-learn requests openpyxl
```

Run notebooks in this order:

1. `API_Socioeconomic_Data_Pull.ipynb` — pulls Census ACS data
2. `cleaning_data_2024.ipynb` — cleans CDC WONDER data
3. `Merging_Cleaning_Data.ipynb` — builds `master_df.csv` and `master_df_rucc.csv`
4. `analysis.ipynb` — runs all four research questions and generates output charts

> **Note:** `Merging_Cleaning_Data.ipynb` downloads USDA RUCC data automatically from the USDA ERS website. Internet access required.

### R Shiny Dashboard

**Requirements:** R 4.2+

Install dependencies:

```r
install.packages(c(
  "shiny", "shinydashboard", "shinyjs",
  "leaflet", "sf", "dplyr", "readr",
  "tigris", "stringr", "plotly", "DT", "viridis"
))
```

Launch the app:

```r
shiny::runApp("shiny/")
```

Or open `shiny/app.R` in RStudio and click **Run App**.

> **Important:** Run `Merging_Cleaning_Data.ipynb` first to generate `data/master_df_rucc.csv`. The app will fall back to `master_df.csv` if the RUCC-enriched file is not present, but the urban–rural filter and RUCC map layer will be unavailable.

---

## 📦 Data Sources

| Source | Description | Years |
|---|---|---|
| [CDC WONDER](https://wonder.cdc.gov/) | Age-adjusted opioid overdose mortality rates per 100,000 population by county. Counties with <10 deaths are suppressed per CDC policy. | 2018–2024 |
| [U.S. Census Bureau ACS](https://www.census.gov/programs-surveys/acs) | 5-year estimates: median household income, poverty rate, unemployment rate, county population | 2018–2024 |
| [SAMHSA Treatment Facility Locator](https://findtreatment.gov/) | Substance abuse treatment facility locations, used to calculate facility counts and rates per 100,000 by county | Current |
| [USDA Rural-Urban Continuum Codes](https://www.ers.usda.gov/data-products/rural-urban-continuum-codes/) | 9-category county classification from most urban (1) to most remote rural (9) | 2023 |

---

## 📐 Key Metrics

**Overdose Rate** — Age-adjusted opioid overdose deaths per 100,000 person-years, aggregated 2018–2024 using cumulative population as the denominator (CDC WONDER methodology).

**Facility Rate** — Number of SAMHSA-listed substance abuse treatment facilities per 100,000 residents (single-year ACS population).

**Access Gap Score** — `Overdose Rate − Facility Rate`. Both are per-100k rates, making them directly comparable. Positive values indicate counties where mortality burden exceeds treatment supply.

**Composite Risk Score** — Equal-weighted average of three normalized components (each scaled 0–1 across all counties):
- Overdose Rate (higher = worse)
- Poverty Rate (higher = worse)
- Facility Rate (lower = worse, i.e., inverted)

Final score scaled to 0–100. Counties missing any component are excluded.

**RUCC** — USDA Rural-Urban Continuum Code. 1 = county in metro area with 1M+ population; 9 = completely rural, not adjacent to any metro area.

---

## 🖥 Shiny Dashboard Features

| Feature | Description |
|---|---|
| **Choropleth Map** | 9 selectable metrics including RUCC urban-rural classification. Click any county for a full data popup. |
| **State Filter** | Multi-select filter applied across map, rankings, and data table. |
| **Urban–Rural Filter** | Filter by Metro (RUCC 1–3), Non-metro (RUCC 4–6), or Rural (RUCC 7–9). |
| **Value Boxes** | Dynamic summaries including "Rural Counties: High Risk & Low Access" count. |
| **County Rankings** | Top 20 bar chart for any selected metric. |
| **At-Risk Table** | Composite risk score table with user-controlled slider (5–100 counties). |
| **Data Table** | Full county dataset with RUCC codes, sortable and searchable. |

---

## ⚠️ Limitations

- **CDC suppression:** Counties with fewer than 10 opioid deaths have missing data, likely underrepresenting rural low-mortality areas.
- **Correlational only:** All findings are observational. Unmeasured confounders (drug supply, state policy, cultural factors) explain remaining variance.
- **Facility presence ≠ access:** SAMHSA data captures whether a facility exists, not capacity, cost, wait times, or whether patients can realistically access care.
- **Time alignment:** ACS 5-year estimates may not perfectly align with the 2018–2024 mortality observation window.

---

## 🔭 Future Directions

- Incorporate DEA fentanyl seizure data by county to separate supply-side from demand-side drivers
- Add state policy covariates (naloxone access laws, Medicaid expansion, prescribing regulations)
- Longitudinal tracking of county risk quadrant movement over time
- Replace facility count with capacity-weighted or utilization-based access measures

---

## 👤 Author

**Josh Tacker** — Data Science Capstone Project, 2026

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
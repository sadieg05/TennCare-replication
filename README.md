TennCare Replication Project

This repository replicates the results of:

Garthwaite, C., Gross, T., & Notowidigdo, M. (2014). Public Health Insurance, Labor Supply, and Employment Lock.

The replication reproduces Tables I and II and Figures II and III using CPS data.

How to Run the Replication

Open the main .do file in Stata.

Choose the control group specification:

"south"

"border"

Insert the chosen specification where indicated in the do-file.

Run the do-file.

The script will generate:

Table 1 (summary statistics)

Table 2 (DiD and DDD estimates)

Figure 2 (public insurance outcomes)

Figure 3 (employment outcomes)

Viewing the Tables in Stata

The exported tables are stored in the output/ folder.

Table 1
use "output/table1_summary_stats_south.dta", clear
list, noobs clean
Table 2
use "output/table2_TableII_PanelsAB_south.dta", clear
format b se p r2 mean_dv %9.4f
list, noobs sepby(panel)

To use the border control group, replace "south" with "border" in the file name (after updating the control group in the do-file).

Figures

The figures appear in Stata after the do-file runs and are also exported to the output/ folder.

Figure 2 (Public Insurance)

output/Figure2A_any_public_DiD_TAG.png

output/Figure2B_any_public_DDD_TAG.png

Figure 3 (Employment)

output/Figure3A_working_DiD_TAG.png

output/Figure3B_working_DDD_TAG.png

TAG equals either "south" or "border" depending on the selected control group.

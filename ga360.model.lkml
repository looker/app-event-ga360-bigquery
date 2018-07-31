connection: "looker_app"

# include all the views
include: "*.view"

# include all the dashboards
# include: "*.lkml"



named_value_format: usd_large {
  value_format: "[>=1000000]$0.00,,\"M\";[>=1000]$0.00,\"K\";$0.00"
}

named_value_format: decimal_large {
  value_format: "[>=1000000000]0.00,,,\"B\";[>=1000000]0.00,,\"M\";[>=1000]0.00,\"K\";0.00"
}

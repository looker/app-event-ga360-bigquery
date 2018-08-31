explore: ga_sessions_base {
  persist_for: "1 hour"
  extension: required
  view_name: ga_sessions
  view_label: "Session"
  join: totals {
    view_label: "Session"
    sql: LEFT JOIN UNNEST([${ga_sessions.totals}]) as totals ;;
    relationship: one_to_one
  }
  join: trafficSource {
    view_label: "Session: Traffic Source"
    sql: LEFT JOIN UNNEST([${ga_sessions.trafficSource}]) as trafficSource ;;
    relationship: one_to_one
  }
  join: adwordsClickInfo {
    view_label: "Session: Traffic Source : Adwords"
    sql: LEFT JOIN UNNEST([ga_sessions.trafficSource.adwordsClickInfo]) as  adwordsClickInfo;;
    relationship: one_to_one
  }

  # join: DoubleClickClickInfo {
  #   view_label: "Session: Traffic Source : DoubleClick"
  #   sql: LEFT JOIN UNNEST([${trafficSource.DoubleClickClickInfo}]) as  DoubleClickClickInfo;;
  #   relationship: one_to_one
  # }
  join: device {
    view_label: "Session: Device"
    sql: LEFT JOIN UNNEST([${ga_sessions.device}]) as device ;;
    relationship: one_to_one
  }
  join: geoNetwork {
    view_label: "Session: Geo Network"
    sql: LEFT JOIN UNNEST([${ga_sessions.geoNetwork}]) as geoNetwork ;;
    relationship: one_to_one
  }
  join: hits {
    view_label: "Session: Hits"
    sql: LEFT JOIN UNNEST(${ga_sessions.hits}) as hits ;;
    relationship: one_to_many
  }
  join: hits_page {
    view_label: "Session: Hits: Page"
    sql: LEFT JOIN UNNEST([${hits.page}]) as hits_page ;;
    relationship: one_to_one
  }
  join: hits_transaction {
    view_label: "Session: Hits: Transaction"
    sql: LEFT JOIN UNNEST([${hits.transaction}]) as hits_transaction ;;
    relationship: one_to_one
  }
  join: hits_item {
    view_label: "Session: Hits: Item"
    sql: LEFT JOIN UNNEST([${hits.item}]) as hits_item ;;
    relationship: one_to_one
  }
  join: hits_social {
    view_label: "Session: Hits: Social"
    sql: LEFT JOIN UNNEST([${hits.social}]) as hits_social ;;
    relationship: one_to_one
  }
  join: hits_publisher {
    view_label: "Session: Hits: Publisher"
    sql: LEFT JOIN UNNEST([${hits.publisher}]) as hits_publisher ;;
    relationship: one_to_one
  }
  join: hits_appInfo {
    view_label: "Session: Hits: App Info"
    sql: LEFT JOIN UNNEST([${hits.appInfo}]) as hits_appInfo ;;
    relationship: one_to_one
  }

  join: hits_eventInfo{
    view_label: "Session: Hits: Events Info"
    sql: LEFT JOIN UNNEST([${hits.eventInfo}]) as hits_eventInfo ;;
    relationship: one_to_one
  }

  # join: hits_sourcePropertyInfo {
  #   view_label: "Session: Hits: Property"
  #   sql: LEFT JOIN UNNEST([hits.sourcePropertyInfo]) as hits_sourcePropertyInfo ;;
  #   relationship: one_to_one
  #   required_joins: [hits]
  # }

  join: hits_eCommerceAction {
    view_label: "Session: Hits: eCommerce"
    sql: LEFT JOIN UNNEST([hits.eCommerceAction]) as  hits_eCommerceAction;;
    relationship: one_to_one
    required_joins: [hits]
  }

  join: hits_product {
    view_label: "Session: Hits: Product"
    sql: LEFT JOIN UNNEST(hits.product) as  hits_product;;
    relationship: one_to_one
    required_joins: [hits]
  }

  join: hits_customDimensions {
    view_label: "Session: Hits: Custom Dimensions"
    sql: LEFT JOIN UNNEST(${hits.customDimensions}) as hits_customDimensions ;;
    relationship: one_to_many
  }
  join: hits_customVariables{
    view_label: "Session: Hits: Custom Variables"
    sql: LEFT JOIN UNNEST(${hits.customVariables}) as hits_customVariables ;;
    relationship: one_to_many
  }
  join: first_hit {
    from: hits
    sql: LEFT JOIN UNNEST(${ga_sessions.hits}) as first_hit ;;
    relationship: one_to_one
    sql_where: ${first_hit.hitNumber} = 1 ;;
    fields: [first_hit.page]
  }
  join: first_page {
    view_label: "Session: First Page Visited"
    from: hits_page
    sql: LEFT JOIN UNNEST([${first_hit.page}]) as first_page ;;
    relationship: one_to_one
  }
}

## Sessions are, by default, constrained by 30 minute intervals

view: ga_sessions_base {
  extension: required

  filter: has_host {
    suggestable: yes
    suggest_dimension: hits_page.hostName
    sql: (SELECT h.page.hostName FROM UNNEST(${ga_sessions.hits}) h
      WHERE {%condition %} h.page.hostName {%endcondition%} LIMIT 1) IS NOT NULL ;;
  }

  filter: has_page {
    suggestable: yes
    suggest_dimension: hits_page.pageTitle
    sql: (SELECT h.page.pageTitle FROM UNNEST(${ga_sessions.hits}) h
      WHERE {%condition %} h.page.pageTitle {%endcondition%} LIMIT 1) IS NOT NULL ;;
  }

  dimension: goal_hit {
    type: yesno
    sql: TRUE ;;
  }

  measure: goal_conversions {
    group_label: "Goals"
    type: count
    filters: {
      field: goal_hit
      value: "Yes"
    }
  }

  measure: goal_conversion_rate {
    description: "URL hits / Sessions"
    group_label: "Goals"
    type: number
    sql: 1.0 * (${goal_conversions}/NULLIF(${ga_sessions.session_count},0));;
    value_format_name: percent_2
  }

  dimension: partition_date {
    type: date_time
    sql: TIMESTAMP(PARSE_DATE('%Y%m%d', REGEXP_EXTRACT(_TABLE_SUFFIX,r'^\d\d\d\d\d\d\d\d')))  ;;
    convert_tz: no
  }

  dimension: id {
    primary_key: yes
    sql: CONCAT(CAST(${fullVisitorId} AS STRING), '|', COALESCE(CAST(${visitId} AS STRING),''), '|', CAST(PARSE_DATE('%Y%m%d', REGEXP_EXTRACT(_TABLE_SUFFIX,r'^\d\d\d\d\d\d\d\d'))   AS STRING)) ;;
  }
  dimension: visitorId {label: "Visitor ID"}

  dimension: visitnumber {
    label: "Visit Number"
    type: number
    description: "The session number for this user. If this is the first session, then this is set to 1."
  }

  dimension:  first_time_visitor {
    type: yesno
    sql: ${visitnumber} = 1 ;;
    full_suggestions: yes
  }

  dimension: visitnumbertier {
    label: "Visit Number Tier"
    type: tier
    tiers: [1,2,5,10,15,20,50,100]
    style: integer
    sql: ${visitnumber} ;;
  }
  dimension: visitId {label: "Visit ID"}
  dimension: fullVisitorId {
    label: "Full Visitor ID"
    tags: ["user_id"]
  }

  dimension: visitStartSeconds {
    label: "Visit Start Seconds"
    type: date_time
    sql: TIMESTAMP_SECONDS(${TABLE}.visitStarttime) ;;
    hidden: yes
  }

  measure: visitStartSeconds_min {
    type: min
    sql: DATE(TIMESTAMP_SECONDS(${TABLE}.visitStarttime)) ;;
    hidden: yes
  }

  measure: visitStartSeconds_max {
    type: max
    sql: DATE(TIMESTAMP_SECONDS(${TABLE}.visitStarttime)) ;;
    hidden: yes
  }

  measure: days_active {
    type: number
    sql: (date_diff(${visitStartSeconds_max}, ${visitStartSeconds_min}, day)+1) ;;
    hidden: no
  }

  measure: weeks_active {
    type: number
    sql: (date_diff(${visitStartSeconds_max}, ${visitStartSeconds_min}, week)+1) ;;
    hidden: yes
  }

  measure: days_since_first_session {
    type: number
    sql:  date_diff(CURRENT_DATE, ${visitStartSeconds_min}, day) ;;
    hidden: yes
  }

  ## referencing partition_date for demo purposes only. Switch this dimension to reference visistStartSeconds
  dimension_group: visitStart {
    timeframes: [date,day_of_week,fiscal_quarter,week,month,year,month_name,month_num,week_of_year,time_of_day, hour_of_day]
    label: "Visit Start"
    type: time
#     datatype: timestamp
    sql: TIMESTAMP_SECONDS(${TABLE}.visitStarttime) ;;
  }
  ## use visit or hit start time instead
  dimension: date {
    hidden: yes
  }
  dimension: socialEngagementType {
    label: "Social Engagement Type"
    full_suggestions: yes}
  dimension: userid {label: "User ID"}

  measure: session_count {
    label: "Sessions"
    type: count
    drill_fields: [fullVisitorId, visitnumber, session_count, totals.transactions_count, totals.transactionRevenue_total]
    value_format_name: decimal_large
  }

  measure: unique_visitors {
    label: "Unique Users"
    type: count_distinct
    sql: ${fullVisitorId} ;;
    drill_fields: [fullVisitorId, visitnumber, session_count, totals.hits, totals.page_views, totals.timeonsite]
    value_format_name: decimal_large
  }

  measure: average_sessions_per_visitor {
    type: number
    sql: 1.0 * (${session_count}/NULLIF(${unique_visitors},0))  ;;
    value_format_name: decimal_2
    drill_fields: [fullVisitorId, visitnumber, session_count, totals.hits, totals.page_views, totals.timeonsite]
  }

  measure: total_visitors {
    type: count
    drill_fields: [fullVisitorId, visitnumber, session_count, totals.hits, totals.page_views, totals.timeonsite]
    value_format_name: decimal_large
  }

  measure: first_time_visitors {
    label: "New Users"
    type: count
    value_format_name: decimal_large
    filters: {
      field: visitnumber
      value: "1"
    }
  }

  measure: percent_new_users {
    type: number
    sql: 1.0 * (${first_time_visitors} / NULLIF(${unique_visitors},0)) ;;
    value_format_name: percent_0
  }


  measure: returning_visitors {
    label: "Returning Users"
    type: count
    value_format_name: decimal_large
    filters: {
      field: visitnumber
      value: "<> 1"
    }
  }

  dimension: channelGrouping {label: "Channel Grouping"}

  # subrecords
  dimension: geoNetwork {hidden: yes}
  dimension: totals {hidden:yes}
  dimension: trafficSource {hidden:yes}
  dimension: device {hidden:yes}
  dimension: customDimensions {hidden:yes}
  dimension: hits {hidden:yes}
  dimension: hits_eventInfo {hidden:yes}

}


view: geoNetwork_base {
  extension: required
  dimension: continent {
    full_suggestions: yes
    drill_fields: [subcontinent,country,region,city,metro,approximate_networkLocation,networkLocation]
  }
  dimension: subcontinent {
    full_suggestions: yes
    drill_fields: [country,region,city,metro,approximate_networkLocation,networkLocation]

  }
  dimension: country {
    full_suggestions: yes
    map_layer_name: countries
    drill_fields: [region,metro,city,approximate_networkLocation,networkLocation]
  }
  dimension: region {
    full_suggestions: yes
    drill_fields: [metro,city,approximate_networkLocation,networkLocation]
  }
  dimension: metro {
    full_suggestions: yes
    drill_fields: [city,approximate_networkLocation,networkLocation]
  }
  dimension: city {
    full_suggestions: yes
    drill_fields: [metro,approximate_networkLocation,networkLocation]}
  dimension: cityid { label: "City ID"}
  dimension: networkDomain {label: "Network Domain"}
  dimension: latitude {
    type: number
    hidden: yes
    sql: CAST(${TABLE}.latitude as FLOAT64);;
  }
  dimension: longitude {
    type: number
    hidden: yes
    sql: CAST(${TABLE}.longitude as FLOAT64);;
  }
  dimension: networkLocation {
    label: "Network Location"
    full_suggestions: yes}
  dimension: location {
    full_suggestions: yes
    type: location
    sql_latitude: ${latitude} ;;
    sql_longitude: ${longitude} ;;
  }
  dimension: approximate_networkLocation {
    type: location
    sql_latitude: ROUND(${latitude},1) ;;
    sql_longitude: ROUND(${longitude},1) ;;
    drill_fields: [networkLocation]
  }
}


view: totals_base {
  extension: required
  dimension: id {
    primary_key: yes
    hidden: yes
    sql: ${ga_sessions.id} ;;
  }
  measure: visits_total {
    type: sum
    sql: ${TABLE}.visits ;;
  }
  measure: hits_total {
    type: sum
    sql: ${TABLE}.hits ;;
    drill_fields: [hits.detail*]
  }
  measure: hits_average_per_session {
    type: number
    sql: 1.0 * ${hits_total} / NULLIF(${ga_sessions.session_count},0) ;;
    value_format_name: decimal_2
  }
  measure: pageviews_total {
    label: "Page Views"
    type: sum
    sql: ${TABLE}.pageviews ;;
    value_format_name: decimal_large
  }

  measure: avg_pageview_per_user {
    label: "Average Pageviews per User"
    type: number
    sql: 1.0 * (${pageviews_total} / NULLIF( ${ga_sessions.unique_visitors},0))  ;;
    value_format_name: decimal_1
  }

  # measure: avg_pageview_to_purchase {
  #   label: "The average number of web pageviews for users who made a purchase"
  #   type: number
  #   sql: 1.0 * (${pageviews_total} / NULLIF( ${ga_sessions.unique_visitors},0))  ;;
  #   value_format_name: decimal_1
  #   filters: {
  #     field: transactions_count
  #     value: ">=1"
  #   }
  # }

  measure: timeonsite_total {
    label: "Time On Site"
    type: sum
    sql: (${TABLE}.timeonsite) / 86400.0 ;;
    value_format: "h:mm:ss"
  }
  dimension: timeonsite_tier {
    label: "Time On Site Tier"
    type: tier
    sql: ${TABLE}.timeonsite ;;
    tiers: [0,15,30,60,120,180,240,300,600]
    style: integer
  }
  measure: timeonsite_average_per_session {
    label: "Avg Session Duration"
    type: number
    sql: 1.0 * ${timeonsite_total} / NULLIF(${ga_sessions.session_count},0) ;;
    value_format: "h:mm:ss"
    }

  measure: page_views_session {
    label: "PageViews Per Session"
    type: number
    sql: 1.0 * ${pageviews_total} / NULLIF(${ga_sessions.session_count},0) ;;
    value_format_name: decimal_2
  }

  measure: bounces_total {
    type: sum
    sql: ${TABLE}.bounces ;;
    value_format_name: decimal_large
  }
  measure: bounce_rate {
    type:  number
    sql: 1.0 * ${bounces_total} / NULLIF(${ga_sessions.session_count},0) ;;
    value_format_name: percent_2
  }

  dimension: transactions {
    sql: ${TABLE}.transactions ;;
  }
  measure: transactions_count {
    type: sum
    label: "Transactions"
    sql: ${transactions} ;;
  }


  measure: transactionRevenue_total {
    label: "Revenue"
    type: sum
    sql: (${TABLE}.transactionRevenue/1000000) ;;
    value_format_name: usd_large
    drill_fields: [transactions_count, transactionRevenue_total]
  }

  measure: transaction_conversion_rate {
    type: number
    sql: 1.0 * (${transactions_count}/NULLIF(${ga_sessions.session_count},0)) ;;
    value_format_name: percent_2
  }

  measure: average_revenue_per_transaction {
    type: number
    sql: 1.0 * (${transactionRevenue_total}/NULLIF(${transactions_count},0)) ;;
    value_format_name: usd
  }

  measure: average_revenue_per_user {
    type: number
    sql: 1.0 * (${transactionRevenue_total}/NULLIF(${ga_sessions.unique_visitors},0)) ;;
    value_format_name: usd
  }

  measure: average_transactions_per_user {
    type: number
    sql: 1.0 * (${transactions_count}/NULLIF(${ga_sessions.unique_visitors},0)) ;;
    value_format_name: decimal_2
  }

  measure: average_sessions_per_user {
    type: number
    sql: 1.0 * (${ga_sessions.session_count}/NULLIF(${ga_sessions.unique_visitors},0)) ;;
    value_format_name: decimal_2
  }


  measure: newVisits_total {
    label: "New Users Total"
    description: "A visit is a session with an interactive event"
    type: sum
    sql: ${TABLE}.newVisits ;;
    value_format_name: decimal_large
  }
  measure: screenViews_total {
    label: "Screen Views Total"
    type: sum
    sql: ${TABLE}.screenViews ;;
  }
  measure: timeOnScreen_total{
    label: "Time On Screen Total"
    type: sum
    sql: ${TABLE}.timeOnScreen ;;
  }
  measure: uniqueScreenViews_total {
    label: "Unique Screen Views Total"
    type: sum
    sql: ${TABLE}.uniqueScreenViews ;;
  }
  dimension: timeOnScreen_total_unique{
    label: "Time On Screen Total"
    type: number
    sql: ${TABLE}.timeOnScreen ;;
  }
}


view: trafficSource_base {
  extension: required

  # dimension: addContent {}
  # dimension: adwords {}
  dimension: referralPath {
    full_suggestions: yes
    label: "Referral Path"}
  dimension: campaign {
    full_suggestions: yes
    suggest_persist_for: "0 seconds"
  }
  dimension: source {
    full_suggestions: yes
  }
  dimension: medium {
    full_suggestions: yes
  }

  dimension: keyword {
    full_suggestions: yes
  }

  dimension: adContent {
    full_suggestions: yes
    label: "Ad Content"
  }
  measure: source_list {
    type: list
    list_field: source
  }
  measure: source_count {
    type: count_distinct
    sql: ${source} ;;
    drill_fields: [source, totals.hits, totals.pageviews]
  }
  measure: keyword_count {
    type: count_distinct
    sql: ${keyword} ;;
    drill_fields: [keyword, totals.hits, totals.pageviews]
  }
  # Subrecords
#   dimension: adwordsClickInfo {}
}


## Analytics uses the last-click model ##
view: adwordsClickInfo_base {
  extension: required
  dimension: campaignId {label: "Campaign ID"}
  dimension: adGroupId {label: "Ad Group ID"}
  dimension: creativeId {label: "Creative ID"}
  dimension: criteriaId {label: "Criteria ID"}
  dimension: page {
    type: number
    description:"Page number in search results where the ad was shown."
  }

  dimension: slot {
    full_suggestions: yes
  }
  dimension: criteriaParameters {
    description: "Descriptive string for the targeting criterion"
    label: "Criteria Parameters"
    full_suggestions: yes
  }

  dimension: gclId {}
  dimension: customerId {label: "Customer ID"}
  dimension: adNetworkType {
    label: "Ad Network Type"
    full_suggestions: yes}
  dimension: targetingCriteria {
    full_suggestions: yes
    label: "Targeting Criteria" hidden:yes}
  dimension: isVideoAd {
    label: "Is Video Ad"
    type: yesno
  }
}


view: device_base {
  extension: required

  dimension: browser {full_suggestions: yes}
  dimension: browserVersion {
    label:"Browser Version"
    full_suggestions: yes}
  dimension: operatingSystem {
    full_suggestions: yes
    label: "Operating System"}
  dimension: operatingSystemVersion {
    full_suggestions: yes
    label: "Operating System Version"}
  dimension: isMobile {
    label: "Is Mobile"
    type: yesno}
  dimension: flashVersion {
    full_suggestions: yes
    label: "Flash Version"}
  dimension: javaEnabled {
    label: "Java Enabled"
    type: yesno
  }
  dimension: language {
    full_suggestions: yes
  }
  dimension: screenColors {
    full_suggestions: yes
    label: "Screen Colors"}
  dimension: screenResolution {
    full_suggestions: yes
    label: "Screen Resolution"}
  dimension: mobileDeviceBranding {
    full_suggestions: yes
    label: "Mobile Device Branding"}
  dimension: mobileDeviceInfo {
    full_suggestions: yes
    label: "Mobile Device Info"}
  dimension: mobileDeviceMarketingName {
    full_suggestions: yes
    label: "Mobile Device Marketing Name"}
  dimension: mobileDeviceModel {
    full_suggestions: yes
    label: "Mobile Device Model"}
  dimension: mobileDeviceInputSelector {
    full_suggestions: yes
    label: "Mobile Device Input Selector"}
}

## A "Hit" is any action that results in data being sent to Google Analytics from your websit. The most common hit types include: pageviews, transactions, events, and social interactions.
## These can be customized for whatever a user wants.

view: hits_base {
  extension: required
  dimension: id {
    primary_key: yes
    sql: CONCAT(${ga_sessions.id},'|',FORMAT('%05d',${hitNumber})) ;;
  }
  dimension: hitNumber {}
  dimension: time {}
  dimension: hitSeconds {
    label: "hit Seconds"
    type: date_time
    sql: TIMESTAMP_MILLIS(visitStarttime*1000 + ${TABLE}.time) ;;
    hidden: yes
  }
  dimension_group: hit {
    timeframes: [date,day_of_week,fiscal_quarter,week,month,year,month_name,month_num,week_of_year]
    type: time
    sql: TIMESTAMP_MILLIS(visitStarttime*1000 + ${TABLE}.time) ;;
  }
  dimension: hour {}
  dimension: minute {}
  dimension: type {}
  dimension: isSecure {
    label: "Is Secure"
    type: yesno
  }
  dimension: isiInteraction {
    label: "Is Interaction"
    type: yesno
  }
  dimension: referer {
    full_suggestions: yes
  }

  measure: count {
    type: count
    drill_fields: [hits.detail*]
  }

  # subrecords
  dimension: page {hidden:yes}
  dimension: transaction {hidden:yes}
  dimension: item {hidden:yes}
  dimension: contentinfo {hidden:yes}
  dimension: social {hidden: yes}
  dimension: publisher {}
  dimension: appInfo {hidden: yes}
  dimension: contentInfo {hidden: yes}
  dimension: customDimensions {hidden: yes}
  dimension: customMetrics {hidden: yes}
  dimension: customVariables {hidden: yes}
  dimension: ecommerceAction {hidden: yes}
  dimension: eventInfo {hidden:yes}
  dimension: exceptionInfo {hidden: yes}
  dimension: experiment {hidden: yes}


  set: detail {
    fields: [ga_sessions.id, ga_sessions.visitnumber, ga_sessions.session_count, hits_page.pagePath, hits.pageTitle]
  }
}

view: hits_page_base {
  extension: required
  dimension: pagePath {
    label: "Page Path"
    link: {
      label: "Link"
      url: "{{ value }}"
    }
    link: {
      label: "Page Info Dashboard"
      url: "/dashboards/101?Page%20Path={{ value | encode_uri}}"
      icon_url: "http://www.looker.com/favicon.ico"
    }
  }
  dimension: hostName {
    full_suggestions: yes
    label: "Host Name"}
  dimension: pageTitle {
    full_suggestions: yes
    label: "Page Title"}
  dimension: searchKeyword {
    full_suggestions: yes
    label: "Search Keyword"}
  dimension: searchCategory{
    full_suggestions: yes
    label: "Search Category"}
}

view: hits_transaction_base {
  extension: required

  dimension: id {
    primary_key: yes
    sql: ${hits.id} ;;
  }
  dimension: transactionShipping {
    full_suggestions: yes
    label: "Transaction Shipping"}
  dimension: affiliation {
    full_suggestions: yes
  }
  dimension: curencyCode {
    full_suggestions: yes
    label: "Curency Code"}
  dimension: localTransactionRevenue {label: "Local Transaction Revenue"}
  dimension: localTransactionTax {label: "Local Transaction Tax"}
  dimension: localTransactionShipping {label: "Local Transaction Shipping"}
}

view: hits_item_base {
  extension: required

  dimension: id {
    primary_key: yes
    sql: ${hits.id} ;;
  }
  dimension: transactionId {label: "Transaction ID"}
  dimension: productName {
    label: "Product Name"
    description: "Name of product on page when hit type is item"
    hidden: yes
    full_suggestions: yes
  }
  dimension: productCategory {
    full_suggestions: yes
    label: "Product Catetory"}
  dimension: productSku {label: "Product Sku"}
  dimension: itemQuantity {label: "Item Quantity"}
  dimension: itemRevenue {label: "Item Revenue"}
  dimension: curencyCode {label: "Curency Code"}
  dimension: localItemRevenue {label:"Local Item Revenue"}
  measure: total_item_revenue {
    type: sum
    sql: ${itemRevenue} ;;
  }
  measure: product_count {
    type: count_distinct
    sql: ${productSku} ;;
    drill_fields: [productName, productCategory, productSku, total_item_revenue]
  }
}

view: hits_social_base {
  extension: required   ## THESE FIELDS WILL ONLY BE AVAILABLE IF VIEW "hits_social" IN GA CUSTOMIZE HAS THE "extends" parameter declared

  dimension: socialInteractionNetwork {
    full_suggestions: yes
    label: "Social Interaction Network"}
  dimension: socialInteractionAction {
    full_suggestions: yes
    label: "Social Interaction Action"}
  dimension: socialInteractions {
    full_suggestions: yes
    label: "Social Interactions"}
  dimension: socialInteractionTarget {
    full_suggestions: yes
    label: "Social Interaction Target"}
  dimension: socialNetwork {
    full_suggestions: yes
    label: "Social Network"}
  dimension: uniqueSocialInteractions {
    label: "Unique Social Interactions"
    type: number
  }
  dimension: hasSocialSourceReferral {
    full_suggestions: yes
    label: "Has Social Source Referral"}
  dimension: socialInteractionNetworkAction {
    full_suggestions: yes
    label: "Social Interaction Network Action"}
}

view: hits_publisher_base {
  extension: required    ## THESE FIELDS WILL ONLY BE AVAILABLE IF VIEW "hits_publisher" IN GA CUSTOMIZE HAS THE "extends" parameter declared

  dimension: dfpClicks {}

  measure: total_dfp_clicks {
    type: sum
    sql: ${dfpClicks} ;;
  }

  measure: total_dfp_impressions {
    type: sum
    sql: ${dfpImpressions} ;;
  }

  measure: total_dfp_revenue {
    description: "Sum of CPM Revenue"
    type: sum
    sql: ${dfpRevenueCpm} ;;
  }

  measure: total_ads_clicks {
    type: sum
    sql: ${adsClicked} ;;
  }

  dimension: dfpImpressions {}
  dimension: dfpMatchedQueries {}
  dimension: dfpMeasurableImpressions {}
  dimension: dfpQueries {}
  dimension: dfpRevenueCpm {}
  dimension: dfpRevenueCpc {}
  dimension: dfpViewableImpressions {}
  dimension: dfpPagesViewed {}
  dimension: adsenseBackfillDfpClicks {}
  dimension: adsenseBackfillDfpImpressions {}
  dimension: adsenseBackfillDfpMatchedQueries {}
  dimension: adsenseBackfillDfpMeasurableImpressions {}
  dimension: adsenseBackfillDfpQueries {}
  dimension: adsenseBackfillDfpRevenueCpm {}
  dimension: adsenseBackfillDfpRevenueCpc {}
  dimension: adsenseBackfillDfpViewableImpressions {}
  dimension: adsenseBackfillDfpPagesViewed {}
  dimension: adxBackfillDfpClicks {}
  dimension: adxBackfillDfpImpressions {}
  dimension: adxBackfillDfpMatchedQueries {}
  dimension: adxBackfillDfpMeasurableImpressions {}
  dimension: adxBackfillDfpQueries {}
  dimension: adxBackfillDfpRevenueCpm {}
  dimension: adxBackfillDfpRevenueCpc {}
  dimension: adxBackfillDfpViewableImpressions {}
  dimension: adxBackfillDfpPagesViewed {}
  dimension: adxClicks {}
  dimension: adxImpressions {}
  dimension: adxMatchedQueries {}
  dimension: adxMeasurableImpressions {}
  dimension: adxQueries {}
  dimension: adxRevenue {}
  dimension: adxViewableImpressions {}
  dimension: adxPagesViewed {}
  dimension: adsViewed {}
  dimension: adsUnitsViewed {}
  dimension: adsUnitsMatched {}
  dimension: viewableAdsViewed {}
  dimension: measurableAdsViewed {}
  dimension: adsPagesViewed {}
  dimension: adsClicked {}
  dimension: adsRevenue {}
  dimension: dfpAdGroup {}
  dimension: dfpAdUnits {}
  dimension: dfpNetworkId {}
}

view: hits_appInfo_base {
  extension: required

  dimension: name {}
  dimension: version {}
  dimension: id {}
  dimension: installerId {}
  dimension: appInstallerId {}
  dimension: appName {}
  dimension: appVersion {}
  dimension: appId {}
  dimension: screenName {}
  dimension: landingScreenName {}
  dimension: exitScreenName {}
  dimension: screenDepth {}
}

view: contentInfo_base {
  extension: required
  dimension: contentDescription {}
}

view: hits_customDimensions_base {
  extension: required
  dimension: index {type:number}
  dimension: value {}
}

view: hits_customMetrics_base {
  extension: required

  dimension: index {type:number}
  dimension: value {}
}

view: hits_customVariables_base {
  extension: required
  dimension: customVarName {}
  dimension: customVarValue {}
  dimension: index {type:number}
}

view: hits_eCommerceAction_base {
  extension: required
  dimension: action_type { type: string hidden: yes}


  ## Build some customizable event funnel off of this
  dimension: action_type_dim {
    order_by_field: action_type
    label: "Action Type"
    type: string
    sql: CASE
          WHEN ${action_type} = '0' THEN 'Unknown'
          WHEN ${action_type} = '1' THEN 'Click through of product lists'
          WHEN ${action_type} = '2' THEN 'Product detail views'
          WHEN ${action_type} = '3' THEN 'Add product(s) to cart'
          WHEN ${action_type} = '4' THEN 'Remove product(s) from cart'
          WHEN ${action_type} = '5' THEN 'Check out'
          WHEN ${action_type} = '6' THEN 'Completed purchase'
          WHEN ${action_type} = '7' THEN 'Refund of purchase'
          WHEN ${action_type} = '8' THEN 'Checkout options'
          ELSE NULL
          END ;;
    full_suggestions: yes
  }



  dimension: option {
    full_suggestions: yes
    description: "This field is populated when a checkout option is specified"
  }
  dimension: step {
    full_suggestions: yes
    description: "This field is populated when a checkout step is specified with the hit."
  }
}

view: hits_eventInfo_base {
  extension: required
  dimension: eventCategory {
    label: "Event Category"
    full_suggestions: yes}

  dimension: eventAction {
    full_suggestions: yes
    label: "Event Action"}
  dimension: eventLabel {
    full_suggestions: yes
    label: "Event Label"}
  dimension: eventValue {
    full_suggestions: yes
    label: "Event Value"}

}

view: hits_product_base {
  extension: required
  dimension: productSKU {}
  dimension: v2ProductName {label: "Product Name"}
  dimension: productRevenue {type:number label:"Product Revenue"}

  dimension: v2ProductCategory {
    label:"Product Category"
  }

  dimension: productVariant {
    label:"Product Variant"
  }

  dimension: productBrand {
    full_suggestions: yes
    label:"Product Brand"
  }

  dimension: localProductRevenue {
    type: number
    label:"Product Revenue (Local Currency)"
  }

  dimension: productPrice {
    type: number
    label:"Product Price"
  }

  dimension: localProductPrice {
    type: number
    label:"Product Price (Local Currency)"
  }

  dimension: ProductQuantity {
    type: number
    label:"Product Quantity"
  }

  dimension: productRefundAmount {
    type: number
    label:"Product Refund Amount"
  }

  dimension: isImpression {
    type: yesno
    label:"Is Impression"
  }

  dimension: isClick {
    type: yesno
    label:"Is Click"
  }

  measure: total_product_revenue {type:sum sql: (1.0 * (${productRevenue}/1000000)) ;; value_format_name:usd_large}
}


# view: hits_sourcePropertyInfo {
# #   extension: required
#   dimension: sourcePropertyDisplayName {label: "Property Display Name"}
# }

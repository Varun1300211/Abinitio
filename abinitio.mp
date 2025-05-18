begin graph complex_data_pipeline

  component input_customer_data
    type input_table
    parameters
      filename "/data/source/customers.csv"
      record_format "csv"
      delimiter ","
      has_header true
    fields
      customer_id int
      name string
      email string
      join_date date "yyyy-MM-dd"
  end component

  component input_order_data
    type input_table
    parameters
      filename "/data/source/orders.csv"
      record_format "csv"
      delimiter ","
      has_header true
    fields
      order_id int
      customer_id int
      order_date date "yyyy-MM-dd"
      total_amount decimal(10,2)
  end component

  component filter_recent_orders
    type filter
    parameters
      condition "order_date >= date_sub(current_date(), interval 1 year)"
    fields
      order_id int
      customer_id int
      order_date date
      total_amount decimal(10,2)
  end component

  component lookup_customer_info
    type lookup
    parameters
      lookup_table "input_customer_data"
      key_fields "customer_id"
      lookup_fields "name,email"
    fields
      order_id int
      customer_id int
      order_date date
      total_amount decimal(10,2)
      name string
      email string
  end component

  component reformat_order_enrichment
    type reformat
    parameters
      transform """
        output.order_id = input.order_id;
        output.customer_id = input.customer_id;
        output.order_date = input.order_date;
        output.total_amount = input.total_amount;
        output.name = input.name;
        output.email = input.email;
        output.order_year = year(input.order_date);
        output.order_month = month(input.order_date);
        output.customer_since_years = year(current_date()) - year(input.join_date);
      """
    fields
      order_id int
      customer_id int
      order_date date
      total_amount decimal(10,2)
      name string
      email string
      order_year int
      order_month int
      customer_since_years int
  end component

  component aggregate_orders
    type aggregate
    parameters
      group_by "customer_id"
      aggregates """
        total_orders = count(order_id);
        total_spent = sum(total_amount);
        avg_order_value = avg(total_amount);
      """
    fields
      customer_id int
      total_orders int
      total_spent decimal(12,2)
      avg_order_value decimal(10,2)
  end component

  component join_customer_summary
    type join
    parameters
      join_type "left_outer"
      keys "customer_id"
    inputs
      left "aggregate_orders"
      right "input_customer_data"
    fields
      customer_id int
      total_orders int
      total_spent decimal(12,2)
      avg_order_value decimal(10,2)
      name string
      email string
      join_date date
  end component

  component output_customer_summary
    type output_table
    parameters
      filename "/data/output/customer_summary.parquet"
      file_format "parquet"
      partition_by "order_year, order_month"
    fields
      customer_id int
      total_orders int
      total_spent decimal(12,2)
      avg_order_value decimal(10,2)
      name string
      email string
      join_date date
  end component

  connect input_order_data -> filter_recent_orders
  connect filter_recent_orders -> lookup_customer_info
  connect lookup_customer_info -> reformat_order_enrichment
  connect reformat_order_enrichment -> aggregate_orders
  connect aggregate_orders -> join_customer_summary.left
  connect input_customer_data -> join_customer_summary.right
  connect join_customer_summary -> output_customer_summary

end graph

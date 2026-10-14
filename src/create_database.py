import pandas as pd
import sqlite3

customers=pd.read_csv(
    'data/olist_customers_dataset.csv', 
    encoding='latin1')

orders=pd.read_csv(
    'data/olist_orders_dataset.csv',
    encoding='latin1'

)

order_items=pd.read_csv(
    'data/olist_order_items_dataset.csv',
    encoding='latin1'
)
payments=pd.read_csv(
    'data/olist_order_payments_dataset.csv',
    encoding='latin1'
)
products=pd.read_csv(
    'data/olist_products_dataset.csv',
    encoding='latin1' 
)

connection=sqlite3.connect('ecommerce.db')

customers.to_sql(
    'customers',
    connection,
    if_exists='replace', index=False

)

orders.to_sql(
    'orders',
    connection,
    if_exists='replace', index=False

)

order_items.to_sql(
    'order_items',
    connection,
    if_exists='replace', index=False
)

payments.to_sql(
    'payments',
    connection,
    if_exists='replace', index=False
)

products.to_sql(
    'products',
    connection,
    if_exists='replace', index=False
)

connection.close()
print('Database created successfully!')
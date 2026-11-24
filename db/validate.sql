DO $$
DECLARE
    spec record;
    row_count bigint;
    key_count bigint;
    orphan_count bigint;
    sales_total numeric;
    quantity_total bigint;
BEGIN
    FOR spec IN
        SELECT * FROM (VALUES
            ('dimcurrency', 'currencykey', 105),
            ('dimdate', 'datekey', 3652),
            ('dimpromotion', 'promotionkey', 16),
            ('dimsalesterritory', 'salesterritorykey', 11),
            ('dimgeography', 'geographykey', 655),
            ('dimcustomer', 'customerkey', 18484),
            ('dimproductcategory', 'productcategorykey', 4),
            ('dimproductsubcategory', 'productsubcategorykey', 37),
            ('dimproduct', 'productkey', 606),
            ('factinternetsales', '(salesordernumber, salesorderlinenumber)', 60398)
        ) AS checks(table_name, key_expression, expected)
    LOOP
        EXECUTE format('SELECT count(*), count(DISTINCT %s) FROM awdw.%I',
                       spec.key_expression, spec.table_name)
           INTO row_count, key_count;
        IF row_count <> spec.expected OR key_count <> row_count THEN
            RAISE EXCEPTION '%: expected % rows and distinct keys, got % rows and % keys',
                spec.table_name, spec.expected, row_count, key_count;
        END IF;
        RAISE NOTICE '%: % rows, % distinct keys', spec.table_name, row_count, key_count;
    END LOOP;

    FOR spec IN
        SELECT * FROM (VALUES
            ('dimgeography', 'salesterritorykey', 'dimsalesterritory', 'salesterritorykey'),
            ('dimcustomer', 'geographykey', 'dimgeography', 'geographykey'),
            ('dimproductsubcategory', 'productcategorykey', 'dimproductcategory', 'productcategorykey'),
            ('dimproduct', 'productsubcategorykey', 'dimproductsubcategory', 'productsubcategorykey'),
            ('factinternetsales', 'productkey', 'dimproduct', 'productkey'),
            ('factinternetsales', 'orderdatekey', 'dimdate', 'datekey'),
            ('factinternetsales', 'duedatekey', 'dimdate', 'datekey'),
            ('factinternetsales', 'shipdatekey', 'dimdate', 'datekey'),
            ('factinternetsales', 'customerkey', 'dimcustomer', 'customerkey'),
            ('factinternetsales', 'promotionkey', 'dimpromotion', 'promotionkey'),
            ('factinternetsales', 'currencykey', 'dimcurrency', 'currencykey'),
            ('factinternetsales', 'salesterritorykey', 'dimsalesterritory', 'salesterritorykey')
        ) AS checks(child_table, child_key, parent_table, parent_key)
    LOOP
        EXECUTE format(
            'SELECT count(*) FROM awdw.%I c WHERE c.%I IS NOT NULL
             AND NOT EXISTS (SELECT FROM awdw.%I p WHERE p.%I = c.%I)',
            spec.child_table, spec.child_key, spec.parent_table, spec.parent_key, spec.child_key
        ) INTO orphan_count;
        IF orphan_count <> 0 THEN
            RAISE EXCEPTION '%.%: % orphaned references to %',
                spec.child_table, spec.child_key, orphan_count, spec.parent_table;
        END IF;
    END LOOP;
    RAISE NOTICE 'All 12 foreign-key relationships verified';

    SELECT sum(salesamount), sum(orderquantity) INTO sales_total, quantity_total
    FROM awdw.factinternetsales;
    IF sales_total IS DISTINCT FROM 29358677.2207::numeric
       OR quantity_total IS DISTINCT FROM 60398::bigint THEN
        RAISE EXCEPTION 'Unexpected totals: SalesAmount %, OrderQuantity %',
            sales_total, quantity_total;
    END IF;
    RAISE NOTICE 'SalesAmount: %, OrderQuantity: %', sales_total, quantity_total;
END
$$;

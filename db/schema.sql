CREATE SCHEMA awdw;

SET LOCAL search_path TO awdw, pg_catalog;

CREATE DOMAIN tinyint AS smallint CHECK (VALUE BETWEEN 0 AND 255);

CREATE TABLE dimcurrency (
    currencykey integer NOT NULL,
    currencyalternatekey char(3) NOT NULL,
    currencyname varchar(50) NOT NULL,
    PRIMARY KEY (currencykey),
    UNIQUE (currencyalternatekey)
);

CREATE TABLE dimdate (
    datekey integer NOT NULL,
    fulldatealternatekey date NOT NULL,
    daynumberofweek tinyint NOT NULL,
    englishdaynameofweek varchar(10) NOT NULL,
    spanishdaynameofweek varchar(10) NOT NULL,
    frenchdaynameofweek varchar(10) NOT NULL,
    daynumberofmonth tinyint NOT NULL,
    daynumberofyear smallint NOT NULL,
    weeknumberofyear tinyint NOT NULL,
    englishmonthname varchar(10) NOT NULL,
    spanishmonthname varchar(10) NOT NULL,
    frenchmonthname varchar(10) NOT NULL,
    monthnumberofyear tinyint NOT NULL,
    calendarquarter tinyint NOT NULL,
    calendaryear smallint NOT NULL,
    calendarsemester tinyint NOT NULL,
    fiscalquarter tinyint NOT NULL,
    fiscalyear smallint NOT NULL,
    fiscalsemester tinyint NOT NULL,
    PRIMARY KEY (datekey),
    UNIQUE (fulldatealternatekey)
);

CREATE TABLE dimpromotion (
    promotionkey integer NOT NULL,
    promotionalternatekey integer,
    englishpromotionname varchar(255),
    spanishpromotionname varchar(255),
    frenchpromotionname varchar(255),
    discountpct double precision,
    englishpromotiontype varchar(50),
    spanishpromotiontype varchar(50),
    frenchpromotiontype varchar(50),
    englishpromotioncategory varchar(50),
    spanishpromotioncategory varchar(50),
    frenchpromotioncategory varchar(50),
    startdate timestamp(3) without time zone NOT NULL,
    enddate timestamp(3) without time zone,
    minqty integer,
    maxqty integer,
    PRIMARY KEY (promotionkey),
    UNIQUE NULLS NOT DISTINCT (promotionalternatekey)
);

CREATE TABLE dimsalesterritory (
    salesterritorykey integer NOT NULL,
    salesterritoryalternatekey integer,
    salesterritoryregion varchar(50) NOT NULL,
    salesterritorycountry varchar(50) NOT NULL,
    salesterritorygroup varchar(50),
    salesterritoryimage bytea,
    PRIMARY KEY (salesterritorykey),
    UNIQUE NULLS NOT DISTINCT (salesterritoryalternatekey)
);

CREATE TABLE dimgeography (
    geographykey integer NOT NULL,
    city varchar(30),
    stateprovincecode varchar(3),
    stateprovincename varchar(50),
    countryregioncode varchar(3),
    englishcountryregionname varchar(50),
    spanishcountryregionname varchar(50),
    frenchcountryregionname varchar(50),
    postalcode varchar(15),
    salesterritorykey integer,
    ipaddresslocator varchar(15),
    PRIMARY KEY (geographykey),
    FOREIGN KEY (salesterritorykey) REFERENCES dimsalesterritory (salesterritorykey)
);

CREATE TABLE dimcustomer (
    customerkey integer NOT NULL,
    geographykey integer,
    customeralternatekey varchar(15) NOT NULL,
    title varchar(8),
    firstname varchar(50),
    middlename varchar(50),
    lastname varchar(50),
    namestyle boolean,
    birthdate date,
    maritalstatus char(1),
    suffix varchar(10),
    gender varchar(1),
    emailaddress varchar(50),
    yearlyincome numeric(19,4),
    totalchildren tinyint,
    numberchildrenathome tinyint,
    englisheducation varchar(40),
    spanisheducation varchar(40),
    frencheducation varchar(40),
    englishoccupation varchar(100),
    spanishoccupation varchar(100),
    frenchoccupation varchar(100),
    houseownerflag char(1),
    numbercarsowned tinyint,
    addressline1 varchar(120),
    addressline2 varchar(120),
    phone varchar(20),
    datefirstpurchase date,
    commutedistance varchar(15),
    PRIMARY KEY (customerkey),
    UNIQUE (customeralternatekey),
    FOREIGN KEY (geographykey) REFERENCES dimgeography (geographykey)
);

CREATE TABLE dimproductcategory (
    productcategorykey integer NOT NULL,
    productcategoryalternatekey integer,
    englishproductcategoryname varchar(50) NOT NULL,
    spanishproductcategoryname varchar(50) NOT NULL,
    frenchproductcategoryname varchar(50) NOT NULL,
    PRIMARY KEY (productcategorykey),
    UNIQUE NULLS NOT DISTINCT (productcategoryalternatekey)
);

CREATE TABLE dimproductsubcategory (
    productsubcategorykey integer NOT NULL,
    productsubcategoryalternatekey integer,
    englishproductsubcategoryname varchar(50) NOT NULL,
    spanishproductsubcategoryname varchar(50) NOT NULL,
    frenchproductsubcategoryname varchar(50) NOT NULL,
    productcategorykey integer,
    PRIMARY KEY (productsubcategorykey),
    UNIQUE NULLS NOT DISTINCT (productsubcategoryalternatekey),
    FOREIGN KEY (productcategorykey) REFERENCES dimproductcategory (productcategorykey)
);

CREATE TABLE dimproduct (
    productkey integer NOT NULL,
    productalternatekey varchar(25),
    productsubcategorykey integer,
    weightunitmeasurecode char(3),
    sizeunitmeasurecode char(3),
    englishproductname varchar(50) NOT NULL,
    spanishproductname varchar(50) NOT NULL,
    frenchproductname varchar(50) NOT NULL,
    standardcost numeric(19,4),
    finishedgoodsflag boolean NOT NULL,
    color varchar(15) NOT NULL,
    safetystocklevel smallint,
    reorderpoint smallint,
    listprice numeric(19,4),
    size varchar(50),
    sizerange varchar(50),
    weight double precision,
    daystomanufacture integer,
    productline char(2),
    dealerprice numeric(19,4),
    class char(2),
    style char(2),
    modelname varchar(50),
    largephoto bytea,
    englishdescription varchar(400),
    frenchdescription varchar(400),
    chinesedescription varchar(400),
    arabicdescription varchar(400),
    hebrewdescription varchar(400),
    thaidescription varchar(400),
    germandescription varchar(400),
    japanesedescription varchar(400),
    turkishdescription varchar(400),
    startdate timestamp(3) without time zone,
    enddate timestamp(3) without time zone,
    status varchar(7),
    PRIMARY KEY (productkey),
    UNIQUE NULLS NOT DISTINCT (productalternatekey, startdate),
    FOREIGN KEY (productsubcategorykey) REFERENCES dimproductsubcategory (productsubcategorykey)
);

CREATE TABLE factinternetsales (
    productkey integer NOT NULL,
    orderdatekey integer NOT NULL,
    duedatekey integer NOT NULL,
    shipdatekey integer NOT NULL,
    customerkey integer NOT NULL,
    promotionkey integer NOT NULL,
    currencykey integer NOT NULL,
    salesterritorykey integer NOT NULL,
    salesordernumber varchar(20) NOT NULL,
    salesorderlinenumber tinyint NOT NULL,
    revisionnumber tinyint NOT NULL,
    orderquantity smallint NOT NULL,
    unitprice numeric(19,4) NOT NULL,
    extendedamount numeric(19,4) NOT NULL,
    unitpricediscountpct double precision NOT NULL,
    discountamount double precision NOT NULL,
    productstandardcost numeric(19,4) NOT NULL,
    totalproductcost numeric(19,4) NOT NULL,
    salesamount numeric(19,4) NOT NULL,
    taxamt numeric(19,4) NOT NULL,
    freight numeric(19,4) NOT NULL,
    carriertrackingnumber varchar(25),
    customerponumber varchar(25),
    orderdate timestamp(3) without time zone,
    duedate timestamp(3) without time zone,
    shipdate timestamp(3) without time zone,
    PRIMARY KEY (salesordernumber, salesorderlinenumber),
    FOREIGN KEY (productkey) REFERENCES dimproduct (productkey),
    FOREIGN KEY (orderdatekey) REFERENCES dimdate (datekey),
    FOREIGN KEY (duedatekey) REFERENCES dimdate (datekey),
    FOREIGN KEY (shipdatekey) REFERENCES dimdate (datekey),
    FOREIGN KEY (customerkey) REFERENCES dimcustomer (customerkey),
    FOREIGN KEY (promotionkey) REFERENCES dimpromotion (promotionkey),
    FOREIGN KEY (currencykey) REFERENCES dimcurrency (currencykey),
    FOREIGN KEY (salesterritorykey) REFERENCES dimsalesterritory (salesterritorykey)
);

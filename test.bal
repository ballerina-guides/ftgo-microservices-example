import ballerina/time;
public type ColumnConfig record {|
   string name?; // Default value will be the field name
   string _type?; // Default type will be inferred from basic ballerina types and sql TypedValues
   boolean isUnique = false;
   boolean autoIncrement = false;
   int incrementInterval = 1;
   boolean isPrimaryKey = false;
|};

public type PrimaryKeyConfig record {|
|};

public annotation ColumnConfig Column on record field;
public annotation PrimaryKeyConfig PrimaryKey on record field;

type StudentPrimaryKey record {|
    int yearJoined;
    int id;
|}

type Student record {|
   @PrimaryKey
   StudentPrimaryKey key;
   string name;
   time:Date dob;
|}

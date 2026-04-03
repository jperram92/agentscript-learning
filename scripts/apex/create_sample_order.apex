String suffix = String.valueOf(Datetime.now().getTime());
String email = 'james@example.com';
String requestedOrderRef = 'ORD-1001';

Pricebook2 standardPricebook = [
    SELECT Id, Name, IsActive
    FROM Pricebook2
    WHERE IsStandard = true
    LIMIT 1
];

if (!standardPricebook.IsActive) {
    standardPricebook.IsActive = true;
    update standardPricebook;
}

Pricebook2 pricebook;
List<Pricebook2> existingPricebooks = [
    SELECT Id, Name, IsActive
    FROM Pricebook2
    WHERE IsStandard = false AND IsActive = true
    ORDER BY CreatedDate ASC
    LIMIT 1
];

if (existingPricebooks.isEmpty()) {
    pricebook = new Pricebook2(
        Name = 'Agentforce Demo Price Book ' + suffix,
        IsActive = true
    );
    insert pricebook;
} else {
    pricebook = existingPricebooks[0];
}

Account accountRecord = new Account(
    Name = 'Acme Demo Customer ' + suffix
);
insert accountRecord;

Contact contactRecord = new Contact(
    FirstName = 'James',
    LastName = 'Demo ' + suffix,
    Email = email,
    AccountId = accountRecord.Id
);
insert contactRecord;

Product2 productRecord = new Product2(
    Name = 'Acme Demo Widget ' + suffix,
    ProductCode = 'DEMO-' + suffix,
    IsActive = true
);
insert productRecord;

PricebookEntry standardPricebookEntryRecord = new PricebookEntry(
    Pricebook2Id = standardPricebook.Id,
    Product2Id = productRecord.Id,
    UnitPrice = 49.99,
    IsActive = true
);
insert standardPricebookEntryRecord;

PricebookEntry pricebookEntryRecord = new PricebookEntry(
    Pricebook2Id = pricebook.Id,
    Product2Id = productRecord.Id,
    UnitPrice = 49.99,
    IsActive = true
);
insert pricebookEntryRecord;

Order orderRecord = new Order(
    AccountId = accountRecord.Id,
    BillToContactId = contactRecord.Id,
    ShipToContactId = contactRecord.Id,
    EffectiveDate = Date.today(),
    Status = 'Draft',
    Pricebook2Id = pricebook.Id,
    PoNumber = requestedOrderRef,
    Description = 'Agentforce demo order for ' + email
);
insert orderRecord;

OrderItem orderItemRecord = new OrderItem(
    OrderId = orderRecord.Id,
    PricebookEntryId = pricebookEntryRecord.Id,
    Quantity = 1,
    UnitPrice = 49.99
);
insert orderItemRecord;

orderRecord = [
    SELECT Id, OrderNumber, Status, EffectiveDate, AccountId, PoNumber
    FROM Order
    WHERE Id = :orderRecord.Id
];

System.debug('SAMPLE_ORDER_CREATED');
System.debug('Order Id: ' + orderRecord.Id);
System.debug('Generated OrderNumber: ' + orderRecord.OrderNumber);
System.debug('Reference PoNumber: ' + orderRecord.PoNumber);
System.debug('Contact Id: ' + contactRecord.Id);
System.debug('Contact Email: ' + contactRecord.Email);
System.debug('Price Book Id: ' + pricebook.Id);

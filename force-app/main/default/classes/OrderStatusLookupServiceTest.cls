@IsTest
private class OrderStatusLookupServiceTest {
    private static Order createTestOrder(String poNumber, String statusValue) {
        Account accountRecord = new Account(Name = 'Acme Test Account');
        insert accountRecord;

        Contact contactRecord = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        Id standardPricebookId = Test.getStandardPricebookId();

        Product2 productRecord = new Product2(
            Name = 'Test Widget',
            ProductCode = 'TEST-WIDGET',
            IsActive = true
        );
        insert productRecord;

        PricebookEntry standardPricebookEntryRecord = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = productRecord.Id,
            UnitPrice = 25,
            IsActive = true
        );
        insert standardPricebookEntryRecord;

        Order orderRecord = new Order(
            AccountId = accountRecord.Id,
            BillToContactId = contactRecord.Id,
            ShipToContactId = contactRecord.Id,
            EffectiveDate = Date.today(),
            Status = statusValue,
            Pricebook2Id = standardPricebookId,
            PoNumber = poNumber,
            Description = 'Test order'
        );
        insert orderRecord;

        OrderItem orderItemRecord = new OrderItem(
            OrderId = orderRecord.Id,
            PricebookEntryId = standardPricebookEntryRecord.Id,
            Quantity = 1,
            UnitPrice = 25
        );
        insert orderItemRecord;

        return [
            SELECT Id, OrderNumber, Status, PoNumber
            FROM Order
            WHERE Id = :orderRecord.Id
        ];
    }

    @IsTest
    static void returnsStatusForNormalOrderIds() {
        Order orderRecord = createTestOrder('ORD-1001', 'Draft');
        OrderStatusLookupService.Request requestItem = new OrderStatusLookupService.Request();
        requestItem.order_id = orderRecord.OrderNumber;

        Test.startTest();
        List<OrderStatusLookupService.Response> responses =
            OrderStatusLookupService.lookup(new List<OrderStatusLookupService.Request>{ requestItem });
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertEquals('Draft', responses[0].order_status);
        System.assert(responses[0].message.contains(orderRecord.OrderNumber));
    }

    @IsTest
    static void returnsStatusWhenLookingUpByPoNumber() {
        createTestOrder('ORD-1001', 'Activated');
        OrderStatusLookupService.Request requestItem = new OrderStatusLookupService.Request();
        requestItem.order_id = 'ORD-1001';

        List<OrderStatusLookupService.Response> responses =
            OrderStatusLookupService.lookup(new List<OrderStatusLookupService.Request>{ requestItem });

        System.assertEquals(true, responses[0].success);
        System.assertEquals('Activated', responses[0].order_status);
    }

    @IsTest
    static void rejectsUnknownOrderIds() {
        OrderStatusLookupService.Request requestItem = new OrderStatusLookupService.Request();
        requestItem.order_id = 'ORD-404';

        List<OrderStatusLookupService.Response> responses =
            OrderStatusLookupService.lookup(new List<OrderStatusLookupService.Request>{ requestItem });

        System.assertEquals(false, responses[0].success);
        System.assertEquals('', responses[0].order_status);
        System.assertEquals(
            'No Salesforce order was found for order number ORD-404.',
            responses[0].message
        );
    }

    @IsTest
    static void rejectsBlankOrderIds() {
        OrderStatusLookupService.Request requestItem = new OrderStatusLookupService.Request();
        requestItem.order_id = '   ';

        List<OrderStatusLookupService.Response> responses =
            OrderStatusLookupService.lookup(new List<OrderStatusLookupService.Request>{ requestItem });

        System.assertEquals(false, responses[0].success);
        System.assertEquals('', responses[0].order_status);
        System.assertEquals('No order number was provided.', responses[0].message);
    }
}

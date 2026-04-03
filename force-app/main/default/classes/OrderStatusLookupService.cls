public with sharing class OrderStatusLookupService {
    public class Request {
        @InvocableVariable(required=true)
        public String order_id;
    }

    public class Response {
        @InvocableVariable
        public String order_status;

        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Lookup Order Status'
        description='Returns the current Salesforce order status for a provided order number.'
    )
    public static List<Response> lookup(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request requestItem : requests) {
            Response responseItem = new Response();
            String rawOrderId = requestItem == null ? null : requestItem.order_id;
            String normalizedOrderId = rawOrderId == null ? '' : rawOrderId.trim();

            if (String.isBlank(normalizedOrderId)) {
                responseItem.success = false;
                responseItem.order_status = '';
                responseItem.message = 'No order number was provided.';
                responses.add(responseItem);
                continue;
            }

            List<Order> matchingOrders = [
                SELECT Id, OrderNumber, Status, PoNumber
                FROM Order
                WHERE OrderNumber = :normalizedOrderId
                    OR PoNumber = :normalizedOrderId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (matchingOrders.isEmpty()) {
                responseItem.success = false;
                responseItem.order_status = '';
                responseItem.message =
                    'No Salesforce order was found for order number ' + normalizedOrderId + '.';
                responses.add(responseItem);
                continue;
            }

            Order matchingOrder = matchingOrders[0];
            responseItem.order_status = matchingOrder.Status;
            responseItem.success = true;
            responseItem.message =
                'Order ' + matchingOrder.OrderNumber + ' is currently ' + responseItem.order_status + '.';
            responses.add(responseItem);
        }

        return responses;
    }
}

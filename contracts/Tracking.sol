// contracts/Tracking.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Tracking {
    // Product structure
    struct Product {
        string productId;
        string name;
        string category;
        string sku;
        uint256 price;
        uint256 quantity;
        string origin;
        address currentOwner;
        uint256 registrationTime;
        bool isActive;
    }

    // Tracking event structure
    struct TrackingEvent {
        uint256 timestamp;
        string location;
        string description;
        address updatedBy;
        string eventType; // "CREATED", "MOVED", "TRANSFERRED", "PROCESSED", "VERIFIED"
    }

    // Verification event structure for analytics
    struct VerificationEvent {
        string productId;
        address verifier;
        string location;
        uint256 timestamp;
        bool isAuthentic;
        uint256 responseTime;
    }

    // Mappings
    mapping(string => Product) public products;
    mapping(string => TrackingEvent[]) public productHistory;
    mapping(string => VerificationEvent[]) public productVerifications;
    mapping(string => bool) public productExists;
    mapping(address => string[]) public ownerProducts;
    string[] public allProductIds;
    
    // Analytics counters
    uint256 public totalProducts;
    uint256 public totalVerifications;
    uint256 public totalEvents;
    
    // Events (enhanced for analytics)
    event ProductRegistered(
        string indexed productId,
        string name,
        address indexed owner,
        uint256 timestamp,
        uint256 price,
        string category
    );
    
    event ProductLocationUpdated(
        string indexed productId,
        string location,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    event ProductOwnershipTransferred(
        string indexed productId,
        address indexed previousOwner,
        address indexed newOwner,
        string reason,
        uint256 timestamp
    );

    event ProductVerified(
        string indexed productId,
        address indexed verifier,
        bool isAuthentic,
        string location,
        uint256 timestamp,
        uint256 responseTime
    );

    event ProductQuantityUpdated(
        string indexed productId,
        uint256 oldQuantity,
        uint256 newQuantity,
        address indexed updatedBy,
        uint256 timestamp
    );

    // Modifiers
    modifier onlyProductOwner(string memory _productId) {
        require(productExists[_productId], "Product does not exist");
        require(
            products[_productId].currentOwner == msg.sender,
            "Only product owner can perform this action"
        );
        _;
    }

    modifier productMustExist(string memory _productId) {
        require(productExists[_productId], "Product does not exist");
        _;
    }

    // Register a new product on the blockchain
    function registerProduct(
        string memory _productId,
        string memory _name,
        string memory _category,
        string memory _sku,
        uint256 _price,
        uint256 _quantity,
        string memory _origin
    ) external {
        require(!productExists[_productId], "Product already exists");
        require(bytes(_productId).length > 0, "Product ID cannot be empty");
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        require(_quantity > 0, "Quantity must be greater than 0");

        // Create new product
        products[_productId] = Product({
            productId: _productId,
            name: _name,
            category: _category,
            sku: _sku,
            price: _price,
            quantity: _quantity,
            origin: _origin,
            currentOwner: msg.sender,
            registrationTime: block.timestamp,
            isActive: true
        });

        // Mark product as existing and update mappings
        productExists[_productId] = true;
        allProductIds.push(_productId);
        ownerProducts[msg.sender].push(_productId);
        totalProducts++;

        // Add initial tracking event
        _addTrackingEvent(_productId, _origin, string(abi.encodePacked("Product registered: ", _name)), "CREATED");

        emit ProductRegistered(_productId, _name, msg.sender, block.timestamp, _price, _category);
    }

    // Verify product (creates verification event for analytics)
    function verifyProduct(
        string memory _productId,
        string memory _location,
        uint256 _responseTime
    ) external productMustExist(_productId) {
        Product memory product = products[_productId];
        bool isAuthentic = product.isActive && product.registrationTime > 0;
        
        // Store verification event
        productVerifications[_productId].push(VerificationEvent({
            productId: _productId,
            verifier: msg.sender,
            location: _location,
            timestamp: block.timestamp,
            isAuthentic: isAuthentic,
            responseTime: _responseTime
        }));

        totalVerifications++;

        // Add tracking event
        _addTrackingEvent(
            _productId,
            _location,
            string(abi.encodePacked(
                "Product verification: ",
                isAuthentic ? "AUTHENTIC" : "FAILED",
                " (Response time: ",
                uintToString(_responseTime),
                "ms)"
            )),
            "VERIFIED"
        );

        emit ProductVerified(_productId, msg.sender, isAuthentic, _location, block.timestamp, _responseTime);
    }

    // Get product details
    function getProductDetails(string memory _productId)
        external
        view
        productMustExist(_productId)
        returns (
            string memory productId,
            string memory name,
            string memory category,
            string memory sku,
            uint256 price,
            uint256 quantity,
            string memory origin,
            address currentOwner,
            uint256 registrationTime,
            bool isActive
        )
    {
        Product memory product = products[_productId];
        return (
            product.productId,
            product.name,
            product.category,
            product.sku,
            product.price,
            product.quantity,
            product.origin,
            product.currentOwner,
            product.registrationTime,
            product.isActive
        );
    }

    // Verify product authenticity
    function verifyProductAuthenticity(string memory _productId)
        external
        view
        returns (bool isAuthentic, string memory verificationMessage)
    {
        if (!productExists[_productId]) {
            return (false, "Product not found on blockchain");
        }

        Product memory product = products[_productId];
        
        if (!product.isActive) {
            return (false, "Product has been deactivated");
        }

        uint256 verificationCount = productVerifications[_productId].length;

        return (true, string(abi.encodePacked(
            "Authentic product registered on ",
            uintToString(product.registrationTime),
            " with ",
            uintToString(productHistory[_productId].length),
            " tracking events and ",
            uintToString(verificationCount),
            " verifications"
        )));
    }

    // Get analytics data
    function getAnalyticsData()
        external
        view
        returns (
            uint256 totalProductsCount,
            uint256 totalVerificationsCount,
            uint256 totalEventsCount,
            uint256 activeProductsCount
        )
    {
        // Count active products
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allProductIds.length; i++) {
            if (products[allProductIds[i]].isActive) {
                activeCount++;
            }
        }
        
        return (
            totalProducts,
            totalVerifications,
            totalEvents,
            activeCount
        );
    }

    // Get total number of registered products
    function getProductCount() external view returns (uint256 count) {
        return totalProducts;
    }

    // Get products by owner
    function getProductsByOwner(address _owner)
        external
        view
        returns (string[] memory ownedProductIds)
    {
        return ownerProducts[_owner];
    }

    // Get recent products for analytics
    function getRecentProducts(uint256 _count)
        external
        view
        returns (string[] memory recentProductIds)
    {
        uint256 totalCount = allProductIds.length;
        uint256 returnCount = _count > totalCount ? totalCount : _count;
        
        string[] memory result = new string[](returnCount);
        
        for (uint256 i = 0; i < returnCount; i++) {
            result[i] = allProductIds[totalCount - 1 - i];
        }
        
        return result;
    }

    // Internal function to add tracking events
    function _addTrackingEvent(
        string memory _productId,
        string memory _location,
        string memory _description,
        string memory _eventType
    ) internal {
        productHistory[_productId].push(TrackingEvent({
            timestamp: block.timestamp,
            location: _location,
            description: _description,
            updatedBy: msg.sender,
            eventType: _eventType
        }));
        
        totalEvents++;
    }

    // Utility function to convert uint to string
    function uintToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        
        return string(buffer);
    }
}
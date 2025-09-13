// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TrueChain Supply Chain Management Contract
 * @dev Manages products and their supply chain tracking (Simplified Version)
 */
contract TrueChain {
    
    // Contract owner
    address public owner;
    
    // Product structure
    struct Product {
        string id;
        string name;
        string description;
        string category;
        uint256 price;
        uint256 stockQuantity;
        string sku;
        uint8 status; // 0: active, 1: lowStock, 2: outOfStock, 3: discontinued
        uint256 weight;
        string dimensions;
        uint256 createdAt;
        address productOwner;
        bool exists;
    }
    
    // Location tracking
    struct LocationUpdate {
        string location;
        uint256 timestamp;
        address updatedBy;
    }
    
    // Shipment structure
    struct Shipment {
        string id;
        string productId;
        string fromLocation;
        string toLocation;
        uint256 quantity;
        uint256 shipmentDate;
        uint256 deliveryDate;
        uint8 status; // 0: pending, 1: inTransit, 2: delivered
        address shipper;
        bool exists;
    }
    
    // Storage mappings
    mapping(string => Product) public products;
    mapping(string => LocationUpdate[]) public productLocations;
    mapping(string => Shipment) public shipments;
    mapping(address => string[]) public userProducts;
    
    // Arrays for enumeration
    string[] public productIds;
    string[] public shipmentIds;
    
    // Events
    event ProductAdded(string indexed productId, string name, address indexed owner);
    event ProductUpdated(string indexed productId, address indexed updatedBy);
    event LocationUpdated(string indexed productId, string location, address indexed updatedBy);
    event ShipmentCreated(string indexed shipmentId, string indexed productId, address indexed shipper);
    event ShipmentStatusUpdated(string indexed shipmentId, uint8 status, address indexed updatedBy);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
    
    modifier productExists(string memory productId) {
        require(products[productId].exists, "Product does not exist");
        _;
    }
    
    modifier shipmentExists(string memory shipmentId) {
        require(shipments[shipmentId].exists, "Shipment does not exist");
        _;
    }
    
    modifier onlyProductOwner(string memory productId) {
        require(products[productId].productOwner == msg.sender, "Not the product owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Add a new product to the supply chain
     */
    function addProduct(
        string memory _id,
        string memory _name,
        string memory _description,
        string memory _category,
        uint256 _price,
        uint256 _stockQuantity,
        string memory _sku,
        uint256 _weight,
        string memory _dimensions
    ) external {
        require(!products[_id].exists, "Product already exists");
        require(bytes(_id).length > 0, "Product ID cannot be empty");
        require(bytes(_name).length > 0, "Product name cannot be empty");
        
        // Determine status based on stock quantity
        uint8 productStatus = 0; // active
        if (_stockQuantity == 0) {
            productStatus = 2; // outOfStock
        } else if (_stockQuantity <= 10) {
            productStatus = 1; // lowStock
        }
        
        Product memory newProduct = Product({
            id: _id,
            name: _name,
            description: _description,
            category: _category,
            price: _price,
            stockQuantity: _stockQuantity,
            sku: _sku,
            status: productStatus,
            weight: _weight,
            dimensions: _dimensions,
            createdAt: block.timestamp,
            productOwner: msg.sender,
            exists: true
        });
        
        products[_id] = newProduct;
        productIds.push(_id);
        userProducts[msg.sender].push(_id);
        
        emit ProductAdded(_id, _name, msg.sender);
    }
    
    /**
     * @dev Update an existing product
     */
    function updateProduct(
        string memory _id,
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _stockQuantity
    ) external productExists(_id) onlyProductOwner(_id) {
        Product storage product = products[_id];
        
        product.name = _name;
        product.description = _description;
        product.price = _price;
        product.stockQuantity = _stockQuantity;
        
        // Update status based on stock
        if (_stockQuantity == 0) {
            product.status = 2; // outOfStock
        } else if (_stockQuantity <= 10) {
            product.status = 1; // lowStock
        } else {
            product.status = 0; // active
        }
        
        emit ProductUpdated(_id, msg.sender);
    }
    
    /**
     * @dev Update product location in supply chain
     */
    function updateLocation(
        string memory _productId,
        string memory _location
    ) external productExists(_productId) {
        require(bytes(_location).length > 0, "Location cannot be empty");
        
        LocationUpdate memory locationUpdate = LocationUpdate({
            location: _location,
            timestamp: block.timestamp,
            updatedBy: msg.sender
        });
        
        productLocations[_productId].push(locationUpdate);
        
        emit LocationUpdated(_productId, _location, msg.sender);
    }
    
    /**
     * @dev Create a new shipment
     */
    function createShipment(
        string memory _shipmentId,
        string memory _productId,
        string memory _fromLocation,
        string memory _toLocation,
        uint256 _quantity
    ) external productExists(_productId) {
        require(!shipments[_shipmentId].exists, "Shipment already exists");
        require(bytes(_shipmentId).length > 0, "Shipment ID cannot be empty");
        require(_quantity > 0, "Quantity must be greater than 0");
        
        Shipment memory newShipment = Shipment({
            id: _shipmentId,
            productId: _productId,
            fromLocation: _fromLocation,
            toLocation: _toLocation,
            quantity: _quantity,
            shipmentDate: block.timestamp,
            deliveryDate: 0,
            status: 0, // pending
            shipper: msg.sender,
            exists: true
        });
        
        shipments[_shipmentId] = newShipment;
        shipmentIds.push(_shipmentId);
        
        emit ShipmentCreated(_shipmentId, _productId, msg.sender);
    }
    
    /**
     * @dev Update shipment status
     */
    function updateShipmentStatus(
        string memory _shipmentId,
        uint8 _status
    ) external shipmentExists(_shipmentId) {
        require(_status <= 2, "Invalid status");
        
        Shipment storage shipment = shipments[_shipmentId];
        shipment.status = _status;
        
        // Set delivery date if status is delivered
        if (_status == 2) {
            shipment.deliveryDate = block.timestamp;
        }
        
        emit ShipmentStatusUpdated(_shipmentId, _status, msg.sender);
    }
    
    /**
     * @dev Verify if a product exists and is authentic
     */
    function verifyProduct(string memory _productId) external view returns (bool) {
        return products[_productId].exists;
    }
    
    /**
     * @dev Get product details (simplified to avoid stack too deep)
     */
    function getProduct(string memory _productId) external view productExists(_productId) returns (
        string memory name,
        string memory description,
        uint256 price,
        uint256 stockQuantity,
        address productOwner
    ) {
        Product memory product = products[_productId];
        return (
            product.name,
            product.description,
            product.price,
            product.stockQuantity,
            product.productOwner
        );
    }
    
    /**
     * @dev Get product additional details
     */
    function getProductDetails(string memory _productId) external view productExists(_productId) returns (
        string memory category,
        string memory sku,
        uint8 status,
        uint256 createdAt
    ) {
        Product memory product = products[_productId];
        return (
            product.category,
            product.sku,
            product.status,
            product.createdAt
        );
    }
    
    /**
     * @dev Get product location history
     */
    function getProductLocations(string memory _productId) external view productExists(_productId) returns (
        string[] memory locations,
        uint256[] memory timestamps,
        address[] memory updaters
    ) {
        LocationUpdate[] memory updates = productLocations[_productId];
        uint256 length = updates.length;
        
        locations = new string[](length);
        timestamps = new uint256[](length);
        updaters = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            locations[i] = updates[i].location;
            timestamps[i] = updates[i].timestamp;
            updaters[i] = updates[i].updatedBy;
        }
        
        return (locations, timestamps, updaters);
    }
    
    /**
     * @dev Get shipment details (simplified)
     */
    function getShipment(string memory _shipmentId) external view shipmentExists(_shipmentId) returns (
        string memory productId,
        string memory fromLocation,
        string memory toLocation,
        uint256 quantity,
        uint8 status
    ) {
        Shipment memory shipment = shipments[_shipmentId];
        return (
            shipment.productId,
            shipment.fromLocation,
            shipment.toLocation,
            shipment.quantity,
            shipment.status
        );
    }
    
    /**
     * @dev Get shipment dates
     */
    function getShipmentDates(string memory _shipmentId) external view shipmentExists(_shipmentId) returns (
        uint256 shipmentDate,
        uint256 deliveryDate,
        address shipper
    ) {
        Shipment memory shipment = shipments[_shipmentId];
        return (
            shipment.shipmentDate,
            shipment.deliveryDate,
            shipment.shipper
        );
    }
    
    /**
     * @dev Get total number of products
     */
    function getTotalProducts() external view returns (uint256) {
        return productIds.length;
    }
    
    /**
     * @dev Get total number of shipments
     */
    function getTotalShipments() external view returns (uint256) {
        return shipmentIds.length;
    }
    
    /**
     * @dev Get products owned by a user
     */
    function getUserProducts(address _user) external view returns (string[] memory) {
        return userProducts[_user];
    }
    
    /**
     * @dev Get all product IDs (for enumeration)
     */
    function getAllProductIds() external view returns (string[] memory) {
        return productIds;
    }
    
    /**
     * @dev Get all shipment IDs (for enumeration)
     */
    function getAllShipmentIds() external view returns (string[] memory) {
        return shipmentIds;
    }
    
    /**
     * @dev Emergency function to transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
}
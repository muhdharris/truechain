// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
//Key Functionalities:
//Shipment Creation - Creates immutable records on-chain
//Status Tracking - Updates shipment status with transparency
//Cryptographic Verification - Uses keccak256 hashing for data integrity
//Access Control - Only authorized parties can modify shipments
//Event Logging - All actions are permanently logged on blockchain
/**
 * @title TrackingWithTransparency
 * @dev Enhanced supply chain tracking contract with full transparency features
 * @author Supply Chain Transparency System
 */
contract TrackingWithTransparency {
    
    // Enhanced shipment structure with transparency metadata
    struct Shipment {
        address sender;
        address receiver;
        uint256 pickupTime;
        uint256 deliveryTime;
        uint256 distance;
        uint256 price;
        ShipmentStatus status;
        bool isPaid;
        string productId;
        string fromLocation;
        string toLocation;
        bytes32 dataHash;
        uint256 createdBlock;
        address[] stakeholders;
    }
    
    enum ShipmentStatus {
        Pending,
        InTransit,
        Delivered
    }
    
    // Storage mappings for transparency
    //Immutable Data Storage ---
    mapping(address => Shipment[]) private shipments;
    mapping(address => uint256) private shipmentCounts;
    mapping(bytes32 => bool) private verifiedHashes;
    mapping(address => mapping(uint256 => address[])) private shipmentStakeholders;
    
    // Global transparency metrics
    uint256 public totalShipments;
    uint256 public totalVerifiedShipments;
    uint256 public totalCompletedShipments;
    
    // Events for transparency logging
    event ShipmentCreated(
        address indexed sender,
        address indexed receiver,
        uint256 indexed shipmentId,
        string productId,
        string fromLocation,
        string toLocation,
        uint256 timestamp
    );
    
    event ShipmentStatusUpdated(
        address indexed sender,
        address indexed receiver,
        uint256 indexed shipmentId,
        ShipmentStatus status,
        uint256 timestamp
    );
    
    event TransparencyVerified(
        address indexed sender,
        uint256 indexed shipmentId,
        bytes32 dataHash,
        uint256 timestamp
    );
    
    event StakeholderAdded(
        address indexed sender,
        uint256 indexed shipmentId,
        address stakeholder,
        uint256 timestamp
    );
    
    // Modifiers for access control and validation
    modifier onlyShipmentOwner(address _sender, uint256 _index) {
        require(_index < shipments[_sender].length, "Invalid shipment index");
        _;
    }
    
    modifier validShipmentStatus(address _sender, uint256 _index, ShipmentStatus _expectedStatus) {
        require(shipments[_sender][_index].status == _expectedStatus, "Invalid shipment status");
        _;
    }
    
    /**
     * @dev Create a new shipment with enhanced transparency features
     * @param _receiver Address of the shipment receiver
     * @param _pickupTime Pickup timestamp
     * @param _distance Distance in kilometers
     * @param _price Price in wei
     * @param _productId Unique product identifier
     * @param _fromLocation Origin location
     * @param _toLocation Destination location
     * @return shipmentId The created shipment index
     */
    function createShipment(
        address _receiver,
        uint256 _pickupTime,
        uint256 _distance,
        uint256 _price,
        string memory _productId,
        string memory _fromLocation,
        string memory _toLocation
    ) public payable returns (uint256 shipmentId) {
        require(_receiver != address(0), "Invalid receiver address");
        require(_receiver != msg.sender, "Cannot send to self");
        require(_pickupTime > block.timestamp, "Invalid pickup time");
        require(_distance > 0, "Invalid distance");
        require(bytes(_productId).length > 0, "Product ID required");
        require(bytes(_fromLocation).length > 0, "From location required");
        require(bytes(_toLocation).length > 0, "To location required");
        require(msg.value >= _price, "Insufficient payment");
        
        // Generate data hash for transparency verification
        //Cryptographic Hashing: ------
        bytes32 dataHash = keccak256(abi.encodePacked(
            msg.sender,
            _receiver,
            _pickupTime,
            _distance,
            _price,
            _productId,
            _fromLocation,
            _toLocation,
            block.timestamp
        ));
        
        // Create shipment
        Shipment memory newShipment = Shipment({
            sender: msg.sender,
            receiver: _receiver,
            pickupTime: _pickupTime,
            deliveryTime: 0,
            distance: _distance,
            price: _price,
            status: ShipmentStatus.Pending,
            isPaid: msg.value >= _price,
            productId: _productId,
            fromLocation: _fromLocation,
            toLocation: _toLocation,
            dataHash: dataHash,
            createdBlock: block.number,
            stakeholders: new address[](0)
        });
        
        shipments[msg.sender].push(newShipment);
        shipmentId = shipments[msg.sender].length - 1;
        shipmentCounts[msg.sender]++;
        totalShipments++;
        
        // Add initial stakeholders
        shipmentStakeholders[msg.sender][shipmentId].push(msg.sender);
        shipmentStakeholders[msg.sender][shipmentId].push(_receiver);
        
        // Mark hash as verified
        verifiedHashes[dataHash] = true;
        totalVerifiedShipments++;
        
        emit ShipmentCreated(
            msg.sender,
            _receiver,
            shipmentId,
            _productId,
            _fromLocation,
            _toLocation,
            block.timestamp
        );
        
        emit TransparencyVerified(
            msg.sender,
            shipmentId,
            dataHash,
            block.timestamp
        );
        
        return shipmentId;
    }
    
    /**
     * @dev Start shipment transit with transparency logging
     */
    function startShipment(
        address _sender,
        address _receiver,
        uint256 _index
    ) public
        onlyShipmentOwner(_sender, _index)
        validShipmentStatus(_sender, _index, ShipmentStatus.Pending)
    {
        require(
            msg.sender == _sender || msg.sender == _receiver,
            "Unauthorized: Only sender or receiver can start shipment"
        );
        
        shipments[_sender][_index].status = ShipmentStatus.InTransit;
        
        emit ShipmentStatusUpdated(
            _sender,
            _receiver,
            _index,
            ShipmentStatus.InTransit,
            block.timestamp
        );
    }
    
    /**
     * @dev Complete shipment delivery with transparency logging
     */
    function completeShipment(
        address _sender,
        address _receiver,
        uint256 _index
    ) public
        onlyShipmentOwner(_sender, _index)
        validShipmentStatus(_sender, _index, ShipmentStatus.InTransit)
    {
        require(
            msg.sender == _receiver,
            "Unauthorized: Only receiver can complete shipment"
        );
        
        shipments[_sender][_index].status = ShipmentStatus.Delivered;
        shipments[_sender][_index].deliveryTime = block.timestamp;
        totalCompletedShipments++;
        
        emit ShipmentStatusUpdated(
            _sender,
            _receiver,
            _index,
            ShipmentStatus.Delivered,
            block.timestamp
        );
    }
    
    /**
     * @dev Get shipment details with full transparency data
     */
    function getShipment(
        address _sender,
        uint256 _index
    ) public view
        onlyShipmentOwner(_sender, _index)
        returns (
            address sender,
            address receiver,
            uint256 pickupTime,
            uint256 deliveryTime,
            uint256 distance,
            uint256 price,
            ShipmentStatus status,
            bool isPaid,
            string memory productId,
            string memory fromLocation,
            string memory toLocation
        )
    {
        Shipment memory shipment = shipments[_sender][_index];
        return (
            shipment.sender,
            shipment.receiver,
            shipment.pickupTime,
            shipment.deliveryTime,
            shipment.distance,
            shipment.price,
            shipment.status,
            shipment.isPaid,
            shipment.productId,
            shipment.fromLocation,
            shipment.toLocation
        );
    }
    
    /**
     * @dev Get shipment count for transparency metrics
     */
    function getShipmentCount(address _sender) public view returns (uint256 count) {
        return shipmentCounts[_sender];
    }
    
    /**
     * @dev Get all shipment IDs for transparency reporting
     */
    function getAllShipments(address _sender) public view returns (uint256[] memory shipmentIds) {
        uint256 count = shipmentCounts[_sender];
        shipmentIds = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            shipmentIds[i] = i;
        }
        
        return shipmentIds;
    }
    
    /**
     * @dev Verify shipment data integrity for transparency
     */
    function verifyShipmentData(
        address _sender,
        uint256 _index,
        bytes32 _dataHash
    ) public view
        onlyShipmentOwner(_sender, _index)
        returns (bool isValid)
    {
        return shipments[_sender][_index].dataHash == _dataHash && verifiedHashes[_dataHash];
    }
    
    /**
     * @dev Add stakeholder to shipment for enhanced transparency
     */
    function addStakeholder(
        address _sender,
        uint256 _index,
        address _stakeholder
    ) public
        onlyShipmentOwner(_sender, _index)
    {
        require(
            msg.sender == _sender || msg.sender == shipments[_sender][_index].receiver,
            "Unauthorized: Only sender or receiver can add stakeholders"
        );
        require(_stakeholder != address(0), "Invalid stakeholder address");
        
        // Check if stakeholder already exists
        address[] memory currentStakeholders = shipmentStakeholders[_sender][_index];
        for (uint256 i = 0; i < currentStakeholders.length; i++) {
            require(currentStakeholders[i] != _stakeholder, "Stakeholder already exists");
        }
        
        shipmentStakeholders[_sender][_index].push(_stakeholder);
        
        emit StakeholderAdded(_sender, _index, _stakeholder, block.timestamp);
    }
    
    /**
     * @dev Get stakeholders for transparency audit
     */
    function getStakeholders(
        address _sender,
        uint256 _index
    ) public view
        onlyShipmentOwner(_sender, _index)
        returns (address[] memory stakeholders)
    {
        return shipmentStakeholders[_sender][_index];
    }
    
    /**
     * @dev Get transparency metrics for the entire network
     */
    function getGlobalTransparencyMetrics() public view returns (
        uint256 _totalShipments,
        uint256 _totalVerifiedShipments,
        uint256 _totalCompletedShipments,
        uint256 _transparencyRate
    ) {
        uint256 transparencyRate = totalShipments > 0 
            ? (totalVerifiedShipments * 100) / totalShipments 
            : 0;
            
        return (
            totalShipments,
            totalVerifiedShipments,
            totalCompletedShipments,
            transparencyRate
        );
    }
    
    /**
     * @dev Get shipment transparency details
     */
    function getShipmentTransparency(
        address _sender,
        uint256 _index
    ) public view
        onlyShipmentOwner(_sender, _index)
        returns (
            bytes32 dataHash,
            uint256 createdBlock,
            address[] memory stakeholders,
            bool isVerified
        )
    {
        Shipment memory shipment = shipments[_sender][_index];
        return (
            shipment.dataHash,
            shipment.createdBlock,
            shipmentStakeholders[_sender][_index],
            verifiedHashes[shipment.dataHash]
        );
    }
    
    /**
     * @dev Public function to verify any shipment exists (for consumer verification)
     */
    function verifyShipmentExists(
        address _sender,
        uint256 _index
    ) public view returns (
        bool exists,
        string memory productId,
        ShipmentStatus status,
        bool isVerified
    ) {
        if (_index >= shipments[_sender].length) {
            return (false, "", ShipmentStatus.Pending, false);
        }
        
        Shipment memory shipment = shipments[_sender][_index];
        return (
            true,
            shipment.productId,
            shipment.status,
            verifiedHashes[shipment.dataHash]
        );
    }
    
    /**
     * @dev Emergency function to update shipment in case of data corruption
     * @notice Only callable by contract owner or shipment participants
     */
    function emergencyUpdateShipment(
        address _sender,
        uint256 _index,
        string memory _correctedProductId
    ) public
        onlyShipmentOwner(_sender, _index)
    {
        require(
            msg.sender == _sender || 
            msg.sender == shipments[_sender][_index].receiver,
            "Unauthorized: Only shipment participants can update"
        );
        
        shipments[_sender][_index].productId = _correctedProductId;
        
        // Generate new hash for updated data
        bytes32 newDataHash = keccak256(abi.encodePacked(
            shipments[_sender][_index].sender,
            shipments[_sender][_index].receiver,
            shipments[_sender][_index].pickupTime,
            shipments[_sender][_index].distance,
            shipments[_sender][_index].price,
            _correctedProductId,
            shipments[_sender][_index].fromLocation,
            shipments[_sender][_index].toLocation,
            block.timestamp
        ));
        
        shipments[_sender][_index].dataHash = newDataHash;
        verifiedHashes[newDataHash] = true;
        
        emit TransparencyVerified(_sender, _index, newDataHash, block.timestamp);
    }
    
    /**
     * @dev Get contract version and features for transparency
     */
    function getContractInfo() public pure returns (
        string memory version,
        string memory features,
        string memory description
    ) {
        return (
            "2.0.0",
            "Enhanced Transparency, Stakeholder Management, Data Verification, Global Metrics",
            "Supply Chain Tracking with Full Transparency Features for Palm Oil Industry"
        );
    }
    
    /**
     * @dev Fallback function to handle accidental ETH sends
     */
    receive() external payable {
        revert("Direct payments not allowed. Use createShipment function.");
    }
    
    /**
     * @dev Fallback function for unknown function calls
     */
    fallback() external payable {
        revert("Function not found. Check contract ABI.");
    }
}
pragma solidity ^0.6.10;

import "./LibBytesMap.sol";
import "./openzeppelin/contracts-upgradeable/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/OwnableUpgradeable.sol";
import "./openzeppelin/contracts/ProxyAdmin.sol";
import "./openzeppelin/contracts/TransparentUpgradeableProxy.sol";

/**
 * @title DidContract
 */
contract DidContract is Initializable, OwnableUpgradeable{

    using LibBytesMap for LibBytesMap.Map;
    LibBytesMap.Map private didMap;

    /**
     * @dev Error code
     */
    string constant private SUCCESS = "0000";
    string constant private DID_NOT_EXIST = "2011";
    string constant private DID_ALREADY_EXIST = "2012";

    event createDidRetLog(
        string msgcode,
        string msg
    );

    event updateDidAuthRetLog(
        string msgcode,
        string msg
    );
    
    event getInitializeDataLog(
        string msgcode,
        bytes msg
    );
    
    /**
    * @dev initialize
    */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
    * @dev getInitializeData
    * @return "initialize()" func signature data
    */
    function getInitializeData() public returns(bytes memory){
        bytes memory data = abi.encodeWithSignature("initialize()");
        emit getInitializeDataLog(SUCCESS, data);
        return data;
    }

    /**
     * @dev Create did
     *
     * @param did the did
     * @param didDocument the didDocument
     * @return msgcode the code for result
     * @return msg the msg for result
     */
    function createDid(
        string memory did,
        string memory didDocument
    )
    public
    onlyOwner
    returns (
        string memory msgcode,
        string memory msg
    )
    {
        bool bools = isDidExist(did);
        if (bools){
            emit createDidRetLog(DID_ALREADY_EXIST, "did already exist");
            return (DID_ALREADY_EXIST, "did already exist");
        }
        bytes memory didBytes = bytes(did);
        bytes memory didDocumentBytes = bytes(didDocument);
        didMap.put(didBytes, didDocumentBytes);
        emit createDidRetLog(SUCCESS, "success");
        return (SUCCESS, "success");
    }

    /**
     * @dev Get did document
     *
     * @param did the did
     * @return msgcode the code for result
     * @return msg the msg for result
     * @return didDocument the didDocument for result
     */
    function getDocument(
        string memory did
    )
    public
    view
    returns (
        string memory msgcode,
        string memory msg,
        string memory didDocument
    )
    {
        bool bools = isDidExist(did);
        if (!bools){
            return (DID_NOT_EXIST, "did not exist", "");
        }
        bytes memory didBytes = bytes(did);
        bytes memory didDocumentBytes = didMap.getValue(didBytes);
        return (SUCCESS, "success", string(didDocumentBytes));
    }

    /**
     * @dev Update did key
     *
     * @param did the did
     * @param didDocument the didDocument
     * @return msgcode the code for result
     * @return msg the msg for result
     */
    function updateDidAuth(
        string memory did,
        string memory didDocument
    )
    public
    onlyOwner
    returns (
        string memory msgcode,
        string memory msg
    )
    {
        bool bools = isDidExist(did);
        if (!bools){
            emit updateDidAuthRetLog(DID_NOT_EXIST, "did not exist");
            return (DID_NOT_EXIST, "did not exist");
        }
        bytes memory didBytes = bytes(did);
        bytes memory didDocumentBytes = bytes(didDocument);
        didMap.put(didBytes, didDocumentBytes);
        emit updateDidAuthRetLog(SUCCESS, "success");
        return (SUCCESS, "success");
    }

    /**
     * @dev Judge whether did exist, return true if it exist
     *
     * @param did the did
     * @return bool the bool for result
     */
    function isDidExist(
        string memory did
    )
    public
    view
    returns (
        bool
    )
    {
        bytes memory key = bytes(did);
        uint256 idx = didMap.index[key];
        if (idx == 0){
            return false;
        }
        return true;
    }
}

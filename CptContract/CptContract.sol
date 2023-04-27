pragma solidity ^0.6.10;

import "./LibBytesMap.sol";
import "./LibBytesMulMap.sol";
import "./UtilsContract.sol";
import "./openzeppelin/contracts-upgradeable/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/OwnableUpgradeable.sol";
import "./openzeppelin/contracts/ProxyAdmin.sol";
import "./openzeppelin/contracts/TransparentUpgradeableProxy.sol";
pragma experimental ABIEncoderV2;

/**
 * @title CptContract
 */
contract CptContract is Initializable, OwnableUpgradeable{

    using LibBytesMap for LibBytesMap.Map;
    LibBytesMap.Map private cptMap;
    LibBytesMap.Map private credMap;

    using LibBytesMulMap for LibBytesMulMap.Map;
    LibBytesMulMap.Map private didCptListMap;
    LibBytesMulMap.Map private didCredListMap;

    uint256 cptNum = 0;

    /**
     * @dev Error code
     */
    string constant private SUCCESS = "0000";
    string constant private CPT_NOT_EXIST = "2001";
    string constant private CPT_ALREADY_EXIST = "2002";
    string constant private CREDLIST_NOT_EXIST = "2003";
    string constant private CREDID_NOT_EXIST = "2004";
    string constant private CPTLIST_NOT_EXIST = "2005";
    string constant private DID_NOT_CORRESPOND_TO_CPTID = "2006";
    string constant private VOUCHER_HAS_BEEN_REVOKED = "2007";
    string constant private CREDINFO_NOT_EXIST = "2008";

    event registerCptRetLog(
        string msgcode,
        string msg
    );

    event updateCptRetLog(
        string msgcode,
        string msg
    );

    event revokeCredentialRetLog(
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
     * @dev Rigister cpt
     *
     * @param did the did
     * @param cptId the cptId
     * @param cpt the cpt info
     * @return msgcode the code for result
     * @return msg the msg for result
     */
    function registerCpt(
        string memory did,
        string memory cptId,
        string memory cpt
    )
    public
    onlyOwner
    returns (
        string memory msgcode,
        string memory msg
    )
    {
        bytes memory didBytes = bytes(did);
        bytes memory cptIdBytes = bytes(cptId);
        bytes memory cptBytes = bytes(cpt);
        bytes[] memory values = new bytes[](1);
        bool bools = isCptListExist(did);
        bool boolss = isCptExist(cptId);
        if (bools && boolss) {
            emit registerCptRetLog(CPT_ALREADY_EXIST, "cpt already exist");
            return (CPT_ALREADY_EXIST, "cpt already exist");
        }
        if (bools){
            bytes[] memory oldDidCptList = didCptListMap.getValue(didBytes);
            bytes[] memory newDidCptList = new bytes[](oldDidCptList.length+1);
            for (uint256 x = 0; x < oldDidCptList.length; x++){
                newDidCptList[x] = oldDidCptList[x];
            }
            newDidCptList[newDidCptList.length-1] = cptIdBytes;
            didCptListMap.put(didBytes, newDidCptList);
            cptMap.put(cptIdBytes, cptBytes);
            cptNum = cptNum + 1;
        }else{
            values[values.length-1] = cptIdBytes;
            didCptListMap.put(didBytes, values);
            cptMap.put(cptIdBytes, cptBytes);
            cptNum = cptNum + 1;
        }
        emit registerCptRetLog(SUCCESS, "success");
        return (SUCCESS, "success");
    }

    /**
     * @dev Get cpt by cptid
     *
     * @param cptId the cpt Id
     * @return msgcode the code for result
     * @return msg the msg for result
     * @return cpt the cpt info for result
     */
    function getCptByCptId(
        string memory cptId
    )
    public
    view
    returns (
        string memory msgcode,
        string memory msg,
        string memory cpt
    )
    {
        bool bools = isCptExist(cptId);
        if (!bools){
            return (CPT_NOT_EXIST, "cpt not exist", "");
        }
        bytes memory cptIdByte = bytes(cptId);
        bytes memory cptbytes = cptMap.getValue(cptIdByte);
        return (SUCCESS, "success", string(cptbytes));
    }

    /**
     * @dev Get cptList by did
     *
     * @param did the did
     * @param page the page
     * @param size the size
     * @return msgcode the code for result
     * @return total the total for result
     * @return totalPage the totalPage for result
     * @return cptlist the cpt info list for result
     */
    function getCptListByDid(
        string memory did,
        uint32 page,
        uint32 size
    )
    public
    view
    returns (
        string memory msgcode,
        uint256 total,
        uint256 totalPage,
        string[] memory cptlist
    )
    {
        bool bools = isCptListExist(did);
        if (!bools){
            return (CPTLIST_NOT_EXIST, 0, 0, new string[](0));
        }
        bytes memory didBytes = bytes(did);
        bytes[] memory didCptListMapValue = didCptListMap.getValue(didBytes);
        bytes[] memory cptlists = new bytes[](didCptListMapValue.length);
        for(uint256 k = 0; k < didCptListMapValue.length; k++){
            cptlists[k] = cptMap.getValue(didCptListMapValue[k]);
        }
        (uint256 totals, uint256 totalPages, string[] memory List) = UtilsContract.pageIndex(page, size, cptlists);
        return (SUCCESS, totals, totalPages, List);
    }

    /**
     * @dev Get all cpt
     *
     * @param page the page
     * @param size the size
     * @return msgcode the code for result
     * @return total the total for result
     * @return totalPage the totalPage for result
     * @return cptlists the cpt all infos list for result
     */
    function getAllCptList(
        uint32 page,
        uint32 size
    )
    public
    view
    returns (
        string memory msgcode,
        uint256 total,
        uint256 totalPage,
        string[] memory cptlists
    )
    {
        uint256 num = 0;
        uint256 k = didCptListMap.iterate_start();
        bytes[] memory cptLists = new bytes[](cptNum);
        while(didCptListMap.can_iterate(k)){
            bytes memory keys = didCptListMap.getKeyByIndex(k);
            bytes[] memory didCptListMapValues = didCptListMap.getValue(keys);
            for(uint256 g = 0; g < didCptListMapValues.length; g++){
                cptLists[num] = didCptListMapValues[g];
                num++;
            }
            k = didCptListMap.iterate_next(k);
        }
        if(cptLists.length == 0){
            return (CPT_NOT_EXIST, 0, 0, new string[](0));
        }

        (uint256 totals, uint256 totalPages, string[] memory List) = UtilsContract.pageIndex(page, size, cptLists);
        return (SUCCESS, totals, totalPages, List);
    }

    /**
     * @dev Update cpt
     *
     * @param did the did
     * @param cptId the cptId
     * @param cpt the cpt info
     * @return msgcode the code for result
     * @return msg the msg for result
     */
    function updateCpt(
        string memory did,
        string memory cptId,
        string memory cpt
    )
    public
    onlyOwner
    returns (
        string memory msgcode,
        string memory msg
    )
    {

        bool bools = isCptListExist(did);
        bool boolss = isCptExist(cptId);
        if (!(bools && boolss)) {
            emit registerCptRetLog(CPT_NOT_EXIST, "cpt not exist");
            return (CPT_NOT_EXIST, "cpt not exist");
        }
        bytes memory didBytes = bytes(did);
        bytes memory cptIdBytes = bytes(cptId);
        bytes memory cptBytes = bytes(cpt);
        bytes[] memory didCpts = didCptListMap.getValue(didBytes);
        for (uint256 w = 0; w < didCpts.length; w++){
            if (UtilsContract.equalBytes(didCpts[w], cptIdBytes)){
                cptMap.put(cptIdBytes, cptBytes);
                emit updateCptRetLog(SUCCESS, "success");
                return (SUCCESS, "success");
            }
        }
        emit updateCptRetLog(DID_NOT_CORRESPOND_TO_CPTID, "did not correspond to cptId");
        return (DID_NOT_CORRESPOND_TO_CPTID, "did not correspond to cptId");
    }

    /**
     * @dev Determine whether CptList exist, and return true if it exist
     *
     * @param did the did
     * @return bool the bool for result
     */
    function isCptListExist(
        string memory did
    )
    public
    view
    returns (
        bool
    )
    {
        bytes memory key = bytes(did);
        uint256 idx = didCptListMap.index[key];
        if (idx == 0){
            return false;
        }
        return true;
    }

    /**
     * @dev Determine whether cpt exist, and return true if it exist
     *
     * @param cptId the did
     * @return bool the bool for result
     */
    function isCptExist(
        string memory cptId
    )
    public
    view
    returns (bool)
    {
        bytes memory key = bytes(cptId);
        uint256 idx = cptMap.index[key];
        if (idx == 0){
            return false;
        }
        return true;
    }

    /**
    Certificate revocation management
    */

    /**
     * @dev Upload voucher number
     *
     * @param did the did
     * @param credId the credId
     * @param info the revocation voucher info
     * @return msgcode the code for result
     * @return msg the msg for result
     */
    function revokeCredential(
        string memory did,
        string memory credId,
        string memory info
    )
    public
    onlyOwner
    returns (
        string memory msgcode,
        string memory msg
    )
    {
        bytes memory didBytes = bytes(did);
        bytes memory credIdBytes = bytes(credId);
        bytes memory infoBytes = bytes(info);
        bytes[] memory credIdList = new bytes[](1);
        bool boolss = isCreIdInfoExist(credId);
        bool bools = isCreListExist(did);
        if (bools){
            if (boolss){
                emit revokeCredentialRetLog(VOUCHER_HAS_BEEN_REVOKED, "Voucher has been revoked");
                return (VOUCHER_HAS_BEEN_REVOKED, "Voucher has been revoked");
            }
            bytes[] memory oldCredIdList = didCredListMap.getValue(didBytes);
            bytes[] memory newCredIdList = new bytes[](oldCredIdList.length+1);
            for (uint256 x = 0; x < oldCredIdList.length; x++){
                newCredIdList[x] = oldCredIdList[x];
            }
            newCredIdList[newCredIdList.length-1] = credIdBytes;
            didCredListMap.put(didBytes, newCredIdList);
            credMap.put(credIdBytes, infoBytes);
        }else{
            if (boolss){
                emit revokeCredentialRetLog(VOUCHER_HAS_BEEN_REVOKED, "Voucher has been revoked");
                return (VOUCHER_HAS_BEEN_REVOKED, "Voucher has been revoked");
            }
            credIdList[0] = credIdBytes;
            didCredListMap.put(didBytes, credIdList);
            credMap.put(credIdBytes, infoBytes);
        }
        emit revokeCredentialRetLog(SUCCESS, "success");
        return (SUCCESS, "success");
    }

    /**
     * @dev Get the revocation list based on did
     *
     * @param did the did
     * @param page the page
     * @param size the size
     * @return msgcode the code for result
     * @return msg the msg for result
     * @return total the total for result
     * @return totalPage the totalPage for result
     * @return list did the corresponding revocation list for result
     */
    function getRevokedCredList(
        string memory did,
        uint32 page,
        uint32 size
    )
    public
    view
    returns (
        string memory msgcode,
        string memory msg,
        uint256 total,
        uint256 totalPage,
        string[] memory list
    )
    {
        bytes memory didBytes = bytes(did);
        bool bools = isCreListExist(did);
        if (!bools){
            return (CREDLIST_NOT_EXIST, "credList not exist", 0, 0,new string[](0));
        }
        bytes[] memory didCredList = didCredListMap.getValue(didBytes);
        bytes[] memory infoBytesList = new bytes[](didCredList.length);
        for (uint256 x = 0; x < didCredList.length; x++){
            bytes memory infoBytes = credMap.getValue(didCredList[x]);
            infoBytesList[x] = infoBytes;
        }
        (uint256 totals, uint256 totalPages, string[] memory List) = UtilsContract.pageIndex(page, size, infoBytesList);
        return (SUCCESS, "success", totals, totalPages, List);
    }

    /**
     * @dev Obtain the voucher based on the did and the number of the revocation voucher
     *
     * @param did the did
     * @param credId the credId
     * @return msgcode the code for result
     * @return msg the msg for result
     * @return info the revocation voucher info for result
     */
    function getRevokedCred(
        string memory did,
        string memory credId
    )
    public
    view
    returns (
        string memory msgcode,
        string memory msg,
        string memory info
    )
    {
        bytes memory didBytes = bytes(did);
        bytes memory credIdBytes = bytes(credId);
        bool bools = isCreListExist(did);
        if (!bools){
            return (CREDLIST_NOT_EXIST, "credList not exist", "");
        }
        bool boolss = isCreIdInfoExist(credId);
        if (!boolss){
            return (CREDINFO_NOT_EXIST, "credInfo_not_exist", "");
        }
        bytes[] memory listss = didCredListMap.getValue(didBytes);
        for(uint256 j = 0; j < listss.length; j++){
            if (UtilsContract.equalBytes(listss[j], credIdBytes)){
                bytes memory info  = credMap.getValue(credIdBytes);
                return (SUCCESS, "success", string(info));
            }
        }
        return (CREDINFO_NOT_EXIST, "credInfo_not_exist", "");
    }

    /**
     * @dev  Determine whether credIdList exist, and return true if it exist
     *
     * @param id the id
     * @return bool the bool for result
     */
    function isCreListExist(
        string memory id
    )
    public
    view
    returns (
        bool
    )
    {
        bytes memory key = bytes(id);
        uint256 idx = didCredListMap.index[key];
        if (idx == 0){
            return false;
        }
        return true;
    }

    /**
     * @dev  Determine whether credIdInfo exist, and return true if it exist
     *
     * @param id the id
     * @return bool the bool for result
     */
    function isCreIdInfoExist(
        string memory id
    )
    public
    view
    returns (
        bool
    )
    {
        bytes memory key = bytes(id);
        uint256 idx = credMap.index[key];
        if (idx == 0){
            return false;
        }
        return true;
    }
}

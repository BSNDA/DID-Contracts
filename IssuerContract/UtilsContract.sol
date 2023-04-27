pragma solidity ^0.6.10;

/**
 * @title UtilsContract
 */
library UtilsContract{

    /** Determine whether a string is empty
     *
     * @param src the string
     * @return bool the bool for result
     */
    function empty(
        string memory src
    )
    private
    pure
    returns(
        bool
    )
    {
        bytes memory src_rep = bytes(src);
        if(src_rep.length == 0) return true;

        for(uint i=0;i<src_rep.length;i++){
            bytes1 b = src_rep[i];
            if(b != 0x20 && b != bytes1(0x09) && b!=bytes1(0x0A) && b!=bytes1(0x0D)) return false;
        }

        return true;
    }

    /** Determine whether two strings are equal
     *
     * @param self the string one
     * @param other the string two
     * @return _bool the bool for result
     */
    function equalString(
        string memory self,
        string memory other
    )
    internal
    pure
    returns(
        bool
    )
    {
        bytes memory self_rep = bytes(self);
        bytes memory other_rep = bytes(other);
        return equalBytes(self_rep, other_rep);
    }

    /** Determine whether two bytes are equal
     *
     * @param self the bytes one
     * @param other the bytes two
     * @return _bool the bool for result
     */
    function equalBytes(
        bytes memory self,
        bytes memory other
    )
    internal
    pure
    returns(
        bool
    )
    {
        if(self.length != other.length){
            return false;
        }
        uint selfLen = self.length;
        for(uint i=0;i<selfLen;i++){
            if(self[i] != other[i]) return false;
        }
        return true;
    }


    /** List pagination
     *
     * @param page the page
     * @param size the size
     * @param org the bytes array
     * @return total the total for result
     * @return totalPage the totalPage for result
     * @return list the list for result
     */
    function pageIndex(
        uint32 page,
        uint32 size,
        bytes[] memory org
    )
    internal
    pure
    returns
    (
        uint256 total,
        uint256 totalPage,
        string[] memory list
    )
    {
        if (page <= 0){
            page = 1;
        }
        if (size <= 0){
            size = 1;
        }
        uint32 index = (page - 1) * size;
        uint256 mapSize = org.length;
        string[] memory issuerList;
        uint256 pages = mapSize / size;
        if(mapSize > pages * size){
            pages = pages + 1;
        }
        if(page > pages){
            return (mapSize, pages, new string[](0));
        }
        if(index > mapSize){
            return (mapSize, pages, new string[](0));
        }
        if(page == 1 && size > mapSize){
            issuerList = new string[](mapSize);
        }else{
            if(mapSize >= index+size){
                issuerList = new string[](size);
            }else{
                issuerList = new string[](mapSize-index);
            }
        }
        for(uint256 j = 0; j < issuerList.length; j++){
            issuerList[j] = string(org[index + j]);
        }
        return (mapSize, pages, issuerList);
    }
}

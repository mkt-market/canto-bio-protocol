// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";
import "../interface/Turnstile.sol";

contract Bio is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of tokens minted
    uint256 public numMinted;

    /// @notice Stores the bio value per NFT
    mapping(uint256 => string) public bio;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event BioAdded(address indexed minter, uint256 indexed nftID, string indexed bio);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenNotMinted(uint256 tokenID);
    error InvalidBioLength(uint256 length);

    /// @notice Initiates CSR on main- and testnet
    constructor() ERC721("Biography", "Bio") {
        if (block.chainid == 7700 || block.chainid == 7701) {
            // Register CSR on Canto main- and testnet
            Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
            turnstile.register(tx.origin);
        }
    }

    /// @notice Get the token URI for the specified _id
    /// @param _id ID to query for
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (_ownerOf[_id] == address(0)) revert TokenNotMinted(_id);
        string memory bioText = bio[_id];
        bytes memory bioTextBytes = bytes(bioText);
        // Check if any characters need to be escaped for the SVG
        (
            uint256 additionalBytesForEscapingSVG,
            uint256 additionalBytesForEscapingJSON
        ) = _getAdditionalBytesForEscaping(bioText);
        string memory bioTextSVG;
        if (additionalBytesForEscapingSVG == 0) {
            bioTextSVG = bioText;
        } else {
            bioTextSVG = string(_escapeSVGCharacters(bioTextBytes, additionalBytesForEscapingSVG));
        }
        bytes memory imageBytes = bytes(
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><style>.c{display:flex;align-items:center;justify-content:center;height:100%;}.bio{font-family:sans-serif;font-size:12px;max-width:34ch;line-height:20px;hyphens:auto;}</style><foreignObject width="100%" height="100%"><div class="c" xmlns="http://www.w3.org/1999/xhtml"><div class="bio">',
                bioTextSVG,
                "</div></div></foreignObject></svg>"
            )
        );
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "Bio #',
                    LibString.toString(_id),
                    '", "description": "',
                    bioText,
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(imageBytes),
                    '"}'
                )
            )
        );
        return string.concat("data:application/json;base64,", json);
    }

    /// @notice Mint a new Bio NFT
    /// @param _bio The text to add
    function mint(string calldata _bio) external {
        // We check the length in bytes, so will be higher for UTF-8 characters. But sufficient for this check
        if (bytes(_bio).length == 0 || bytes(_bio).length > 200) revert InvalidBioLength(bytes(_bio).length);
        uint256 tokenId = ++numMinted;
        bio[tokenId] = _bio;
        _mint(msg.sender, tokenId);
        emit BioAdded(msg.sender, tokenId, _bio);
    }

    /// @notice Count how many bytes are needed to escape the chars in _text
    /// @param _text Text to analyze
    /// @return escapeBytesSVG Number of bytes for escaping in SVG, escapeBytesJSON Number of bytes for escaping in JSON
    function _getAdditionalBytesForEscaping(
        string memory _text
    ) private pure returns (uint256 escapeBytesSVG, uint256 escapeBytesJSON) {
        bytes memory textBytes = bytes(_text);
        for (uint i; i < textBytes.length; ++i) {
            if (textBytes[i] == "<" || textBytes[i] == ">") {
                escapeBytesSVG += 3; // &lt; / &gt;
            } else if (textBytes[i] == "&") {
                escapeBytesSVG += 4; // &amp;
            } else if (textBytes[i] == '"') {
                escapeBytesSVG += 5; // &quot;
                escapeBytesJSON++; // \"
            } else if (textBytes[i] == "'") {
                escapeBytesSVG += 5; // &apos;
            } else if (
                textBytes[i] == "\\" ||
                textBytes[i] == "/" ||
                uint8(textBytes[i]) == 8 || // Backspace
                uint8(textBytes[i]) == 12 || // Formfeed
                textBytes[i] == "\n" ||
                textBytes[i] == "\r" ||
                textBytes[i] == "\t"
            ) {
                escapeBytesJSON++;
            }
        }
    }

    /// @notice Escape all SVG characters in _srcString
    /// @param _srcString Source string to escape
    /// @param _bytesNeededForEscaping How many bytes are needed for escaping, i.e. how much larger the string will be
    /// @return The escaped string
    function _escapeSVGCharacters(
        bytes memory _srcString,
        uint256 _bytesNeededForEscaping
    ) private pure returns (bytes memory) {
        bytes memory dstString = new bytes(_srcString.length + _bytesNeededForEscaping);
        uint256 j;
        for (uint i; i < _srcString.length; ++i) {
            if (_srcString[i] == "<") {
                dstString[j++] = "&";
                dstString[j++] = "l";
                dstString[j++] = "t";
                dstString[j++] = ";";
            } else if (_srcString[i] == ">") {
                dstString[j++] = "&";
                dstString[j++] = "g";
                dstString[j++] = "t";
                dstString[j++] = ";";
            } else if (_srcString[i] == "&") {
                dstString[j++] = "&";
                dstString[j++] = "a";
                dstString[j++] = "m";
                dstString[j++] = "p";
                dstString[j++] = ";";
            } else if (_srcString[i] == "'") {
                dstString[j++] = "&";
                dstString[j++] = "a";
                dstString[j++] = "p";
                dstString[j++] = "o";
                dstString[j++] = "s";
                dstString[j++] = ";";
            } else if (_srcString[i] == '"') {
                dstString[j++] = "&";
                dstString[j++] = "q";
                dstString[j++] = "u";
                dstString[j++] = "o";
                dstString[j++] = "t";
                dstString[j++] = ";";
            } else {
                dstString[j++] = _srcString[i];
            }
        }
        return dstString;
    }
}

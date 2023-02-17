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
    uint256 numMinted;

    /// @notice Stores the bio value per NFT
    mapping(uint256 => string) bio;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event BioAdded(address indexed minter, uint256 indexed nftID, string indexed bio);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenNotMinted(uint256 tokenID);
    error InvalidBioLength(uint256 length);

    /// @notice Initiates CSR on mainnet
    constructor() ERC721("Biography", "Bio") {
        if (block.chainid == 7700) {
            // Register CSR on Canto mainnnet
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
        uint lengthInBytes = bioTextBytes.length;
        // Insert a new line after 40 characters, taking into account unicode character
        uint lines = (lengthInBytes - 1) / 40 + 1;
        string[] memory strLines = new string[](lines);
        bool prevByteWasContinuation;
        uint256 insertedLines;
        bytes memory bytesLines = new bytes(44);
        uint bytesOffset;
        for (uint i; i < lengthInBytes; ++i) {
            bytes1 character = bioTextBytes[i];
            bytesLines[bytesOffset] = character;
            bytesOffset++;
            if ((i > 0 && (i + 1) % 40 == 0) || prevByteWasContinuation || i == lengthInBytes - 1) {
                bytes1 nextCharacter;
                if (i != lengthInBytes - 1) {
                    nextCharacter = bioTextBytes[i + 1];
                }
                if (nextCharacter & 0x80 == 0 || nextCharacter & 0xC0 == 0xC0 || i == lengthInBytes - 1) {
                    // ASCII character or Unicode start byte or last byte
                    // TODO: Technically could split on an emoji modifier
                    assembly {
                        mstore(bytesLines, bytesOffset)
                    }
                    strLines[insertedLines++] = string(bytesLines);
                    bytesLines = new bytes(44);
                    prevByteWasContinuation = false;
                    bytesOffset = 0;
                } else if (nextCharacter & 0xC0 == 0x80) {
                    // Unicode continuation byte
                    prevByteWasContinuation = true;
                }
            }
        }
        string
            memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 100"><style>text { font-family: sans-serif; font-size: 12px; }</style>';
        string memory text = '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">';
        for (uint i; i < lines; ++i) {
            text = string.concat(text, '<tspan x="50%" dy="20">', strLines[i], "</tspan>");
        }
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "Bio #',
                    LibString.toString(_id),
                    '", "description": "',
                    bioText,
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(string.concat(svg, text, "</text></svg>"))),
                    '"}'
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
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
}

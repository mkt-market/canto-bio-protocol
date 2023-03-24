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
        bytes memory imageBytes = bytes(
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><style>.c{display:flex;align-items:center;justify-content:center;height:100%;}.bio{font-family:sans-serif;font-size:12px;max-width:34ch;line-height:20px;hyphens:auto;}</style><foreignObject width="100%" height="100%"><div class="c" xmlns="http://www.w3.org/1999/xhtml"><div class="bio">',
                bioText,
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
}

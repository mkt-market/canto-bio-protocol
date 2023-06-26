// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Turnstile} from "../interface/Turnstile.sol";
import {ICidNFT, IAddressRegistry} from "../interface/ICidNFT.sol";
import {ICidSubprotocol} from "../interface/ICidSubprotocol.sol";

contract Bio is ERC721Enumerable, Owned {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of tokens minted
    uint256 public numMinted;

    /// @notice Whether minting is enabled
    bool public mintingEnabled = true;

    /// @notice Stores the bio value per NFT
    mapping(uint256 => string) public bio;

    /// @notice Name with which the subprotocol is registered
    string public subprotocolName;

    /// @notice Url of the docs
    string public docs;

    /// @notice Urls of the library
    string[] private libraries;

    /// @notice Reference to the CID NFT
    ICidNFT private immutable cidNFT;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event BioAdded(address indexed minter, uint256 indexed nftID, string indexed bio);
    event DocsChanged(string newDocs);
    event LibChanged(string[] newLibs);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenNotMinted(uint256 tokenID);
    error InvalidBioLength(uint256 length);
    error MintingDisabled();

    /// @notice Initiates CSR on main- and testnet
    /// @param _cidNFT Reference to CID
    /// @param _subprotocolName Name with which the subprotocol is registered
    constructor(address _cidNFT, string memory _subprotocolName) ERC721("Biography", "Bio") Owned(msg.sender) {
        subprotocolName = _subprotocolName;
        cidNFT = ICidNFT(_cidNFT);
        if (block.chainid == 7700 || block.chainid == 7701) {
            // Register CSR on Canto main- and testnet
            Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
            turnstile.register(tx.origin);
        }
    }

    /// @notice Get the token URI for the specified _id
    /// @param _id ID to query for
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (!_exists(_id)) revert TokenNotMinted(_id);
        string memory bioText = bio[_id];
        string memory bioTextSVG = LibString.escapeHTML(bioText);
        string memory bioTextJSON = LibString.escapeJSON(bioText);
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
                    bioTextJSON,
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
        if (!mintingEnabled) revert MintingDisabled();
        // We check the length in bytes, so will be higher for UTF-8 characters. But sufficient for this check
        if (bytes(_bio).length == 0 || bytes(_bio).length > 200) revert InvalidBioLength(bytes(_bio).length);
        uint256 tokenId = ++numMinted;
        bio[tokenId] = _bio;
        _mint(msg.sender, tokenId);
        emit BioAdded(msg.sender, tokenId, _bio);
    }

    /// @notice Get the subprotocol metadata that is associated with a subprotocol NFT
    /// @param _tokenID The NFT to query
    /// @return Subprotocol metadata as JSON
    function metadata(uint256 _tokenID) external view returns (string memory) {
        if (!_exists(_tokenID)) revert TokenNotMinted(_tokenID);
        (uint256 cidNFTID, address cidNFTRegisteredAddress) = _getAssociatedCIDAndOwner(_tokenID);
        string memory subprotocolData = string.concat('"bio": "', LibString.escapeJSON(bio[_tokenID]), '"');
        string memory json = string.concat(
            "{",
            '"subprotocolName": "',
            subprotocolName,
            '",',
            '"associatedCidToken":',
            Strings.toString(cidNFTID),
            ",",
            '"associatedCidAddress": "',
            Strings.toHexString(uint160(cidNFTRegisteredAddress), 20),
            '",',
            '"subprotocolData": {',
            subprotocolData,
            "}"
            "}"
        );
        return json;
    }

    /// @notice Return the libraries / SDKs of the subprotocol (if any)
    /// @return Location of the subprotocol library
    function lib() external view returns (string[] memory) {
        return libraries;
    }

    /// @notice Change the docs url
    /// @param _newDocs New docs url
    function changeDocs(string memory _newDocs) external onlyOwner {
        docs = _newDocs;
        emit DocsChanged(_newDocs);
    }

    /// @notice Change the lib urls
    /// @param _newLibs New lib urls
    function changeLib(string[] memory _newLibs) external onlyOwner {
        libraries = _newLibs;
        emit LibChanged(_newLibs);
    }

    /// @notice Get the associated CID NFT ID and the address that has registered this CID (if any)
    /// @param _subprotocolNFTID ID of the subprotocol NFT to query
    /// @return cidNFTID The CID NFT ID, cidNFTRegisteredAddress The registered address
    function _getAssociatedCIDAndOwner(
        uint256 _subprotocolNFTID
    ) internal view returns (uint256 cidNFTID, address cidNFTRegisteredAddress) {
        cidNFTID = cidNFT.getPrimaryCIDNFT(subprotocolName, _subprotocolNFTID);
        IAddressRegistry addressRegistry = cidNFT.addressRegistry();
        cidNFTRegisteredAddress = addressRegistry.getAddress(cidNFTID);
    }

    /// @notice Change the reference to the subprotocol name
    /// @param _subprotocolName New subprotocol name
    function changeSubprotocolName(string memory _subprotocolName) external onlyOwner {
        subprotocolName = _subprotocolName;
    }

    /// @notice Enable or disable minting
    /// @param _mintingEnabled New value for toggle
    function setMintingEnabled(bool _mintingEnabled) external onlyOwner {
        mintingEnabled = _mintingEnabled;
    }
}

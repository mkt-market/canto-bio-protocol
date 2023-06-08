// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../Bio.sol";

contract BioTest is Test {
    Bio public bio;
    address public alice;

    event BioAdded(address indexed minter, uint256 indexed nftID, string indexed bio);

    error TokenNotMinted(uint256 tokenID);
    error InvalidBioLength(uint256 length);

    function setUp() public {
        bio = new Bio(address(0), "");
        alice = address(1);
    }

    function slice(string memory str, uint256 startIndex, uint256 endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex < endIndex, "Invalid indices");
        require(endIndex <= strBytes.length, "End index out of range");

        bytes memory sliced = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            sliced[i - startIndex] = strBytes[i];
        }
        return string(sliced);
    }

    function countSubStr(string memory str, string memory substr) public pure returns (uint256) {
        uint256 count = 0;
        uint256 len = bytes(str).length;
        uint256 sublen = bytes(substr).length;
        if (len < sublen) return 0;
        for (uint256 i = 0; i <= len - sublen; i++) {
            bool found = true;
            for (uint256 j = 0; j < sublen; j++) {
                if (bytes(str)[i + j] != bytes(substr)[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                count++;
            }
        }
        return count;
    }

    function testMint() public {
        string memory _bio = "TEST BIO";
        uint256 prevNnumMinted = bio.numMinted();
        uint256 nnumMinted = prevNnumMinted + 1;

        vm.expectEmit(true, true, true, true);
        emit BioAdded(alice, nnumMinted, _bio);

        vm.prank(alice);
        bio.mint(_bio);

        assertEq(bio.numMinted(), nnumMinted, "Wrong tokenId");
        assertEq(bio.bio(nnumMinted), _bio, "Wrong _bio");
        assertEq(bio.ownerOf(nnumMinted), alice, "NFT not minted");
    }

    function testShortString() public {
        string memory text = "Lorem ipsum dolor sit amet";
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        assertEq(
            uri,
            "data:application/json;base64,eyJuYW1lIjogIkJpbyAjMSIsICJkZXNjcmlwdGlvbiI6ICJMb3JlbSBpcHN1bSBkb2xvciBzaXQgYW1ldCIsICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUI0Yld4dWN6MGlhSFIwY0RvdkwzZDNkeTUzTXk1dmNtY3ZNakF3TUM5emRtY2lJSFpwWlhkQ2IzZzlJakFnTUNBME1EQWdNakF3SWo0OGMzUjViR1UrTG1ON1pHbHpjR3hoZVRwbWJHVjRPMkZzYVdkdUxXbDBaVzF6T21ObGJuUmxjanRxZFhOMGFXWjVMV052Ym5SbGJuUTZZMlZ1ZEdWeU8yaGxhV2RvZERveE1EQWxPMzB1WW1sdmUyWnZiblF0Wm1GdGFXeDVPbk5oYm5NdGMyVnlhV1k3Wm05dWRDMXphWHBsT2pFeWNIZzdiV0Y0TFhkcFpIUm9Pak0wWTJnN2JHbHVaUzFvWldsbmFIUTZNakJ3ZUR0b2VYQm9aVzV6T21GMWRHODdmVHd2YzNSNWJHVStQR1p2Y21WcFoyNVBZbXBsWTNRZ2QybGtkR2c5SWpFd01DVWlJR2hsYVdkb2REMGlNVEF3SlNJK1BHUnBkaUJqYkdGemN6MGlZeUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5MekU1T1RrdmVHaDBiV3dpUGp4a2FYWWdZMnhoYzNNOUltSnBieUkrVEc5eVpXMGdhWEJ6ZFcwZ1pHOXNiM0lnYzJsMElHRnRaWFE4TDJScGRqNDhMMlJwZGo0OEwyWnZjbVZwWjI1UFltcGxZM1ErUEM5emRtYysifQ=="
        );
        assertEq(
            svg,
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><style>.c{display:flex;align-items:center;justify-content:center;height:100%;}.bio{font-family:sans-serif;font-size:12px;max-width:34ch;line-height:20px;hyphens:auto;}</style><foreignObject width="100%" height="100%"><div class="c" xmlns="http://www.w3.org/1999/xhtml"><div class="bio">Lorem ipsum dolor sit amet</div></div></foreignObject></svg>'
        );
    }

    function testLongString() public {
        string
            memory text = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dol";
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        assertEq(
            uri,
            "data:application/json;base64,eyJuYW1lIjogIkJpbyAjMSIsICJkZXNjcmlwdGlvbiI6ICJMb3JlbSBpcHN1bSBkb2xvciBzaXQgYW1ldCwgY29uc2V0ZXR1ciBzYWRpcHNjaW5nIGVsaXRyLCBzZWQgZGlhbSBub251bXkgZWlybW9kIHRlbXBvciBpbnZpZHVudCB1dCBsYWJvcmUgZXQgZG9sb3JlIG1hZ25hIGFsaXF1eWFtIGVyYXQsIHNlZCBkaWFtIHZvbHVwdHVhLiBBdCB2ZXJvIGVvcyBldCBhY2N1c2FtIGV0IGp1c3RvIGR1byBkb2wiLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCNGJXeHVjejBpYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNpSUhacFpYZENiM2c5SWpBZ01DQTBNREFnTWpBd0lqNDhjM1I1YkdVK0xtTjdaR2x6Y0d4aGVUcG1iR1Y0TzJGc2FXZHVMV2wwWlcxek9tTmxiblJsY2p0cWRYTjBhV1o1TFdOdmJuUmxiblE2WTJWdWRHVnlPMmhsYVdkb2REb3hNREFsTzMwdVltbHZlMlp2Ym5RdFptRnRhV3g1T25OaGJuTXRjMlZ5YVdZN1ptOXVkQzF6YVhwbE9qRXljSGc3YldGNExYZHBaSFJvT2pNMFkyZzdiR2x1WlMxb1pXbG5hSFE2TWpCd2VEdG9lWEJvWlc1ek9tRjFkRzg3ZlR3dmMzUjViR1UrUEdadmNtVnBaMjVQWW1wbFkzUWdkMmxrZEdnOUlqRXdNQ1VpSUdobGFXZG9kRDBpTVRBd0pTSStQR1JwZGlCamJHRnpjejBpWXlJZ2VHMXNibk05SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR2gwYld3aVBqeGthWFlnWTJ4aGMzTTlJbUpwYnlJK1RHOXlaVzBnYVhCemRXMGdaRzlzYjNJZ2MybDBJR0Z0WlhRc0lHTnZibk5sZEdWMGRYSWdjMkZrYVhCelkybHVaeUJsYkdsMGNpd2djMlZrSUdScFlXMGdibTl1ZFcxNUlHVnBjbTF2WkNCMFpXMXdiM0lnYVc1MmFXUjFiblFnZFhRZ2JHRmliM0psSUdWMElHUnZiRzl5WlNCdFlXZHVZU0JoYkdseGRYbGhiU0JsY21GMExDQnpaV1FnWkdsaGJTQjJiMngxY0hSMVlTNGdRWFFnZG1WeWJ5QmxiM01nWlhRZ1lXTmpkWE5oYlNCbGRDQnFkWE4wYnlCa2RXOGdaRzlzUEM5a2FYWStQQzlrYVhZK1BDOW1iM0psYVdkdVQySnFaV04wUGp3dmMzWm5QZz09In0="
        );
        assertEq(
            svg,
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><style>.c{display:flex;align-items:center;justify-content:center;height:100%;}.bio{font-family:sans-serif;font-size:12px;max-width:34ch;line-height:20px;hyphens:auto;}</style><foreignObject width="100%" height="100%"><div class="c" xmlns="http://www.w3.org/1999/xhtml"><div class="bio">Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dol</div></div></foreignObject></svg>'
        );
    }

    function testEscaping() public {
        string memory text = string.concat(
            "<>'\"&\\/\n\r\t",
            string(abi.encodePacked(bytes1(uint8(8)), bytes1(uint8(12))))
        );
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svgB64 = string(slice(json, 74 + bytes(text).length + 7, bytes(json).length - 2)); // 7 escpaed JSON characters
        assertEq(
            uri,
            "data:application/json;base64,eyJuYW1lIjogIkJpbyAjMSIsICJkZXNjcmlwdGlvbiI6ICI8PidcIiZcXC9cblxyXHRcYlxmIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0EwTURBZ01qQXdJajQ4YzNSNWJHVStMbU43WkdsemNHeGhlVHBtYkdWNE8yRnNhV2R1TFdsMFpXMXpPbU5sYm5SbGNqdHFkWE4wYVdaNUxXTnZiblJsYm5RNlkyVnVkR1Z5TzJobGFXZG9kRG94TURBbE8zMHVZbWx2ZTJadmJuUXRabUZ0YVd4NU9uTmhibk10YzJWeWFXWTdabTl1ZEMxemFYcGxPakV5Y0hnN2JXRjRMWGRwWkhSb09qTTBZMmc3YkdsdVpTMW9aV2xuYUhRNk1qQndlRHRvZVhCb1pXNXpPbUYxZEc4N2ZUd3ZjM1I1YkdVK1BHWnZjbVZwWjI1UFltcGxZM1FnZDJsa2RHZzlJakV3TUNVaUlHaGxhV2RvZEQwaU1UQXdKU0krUEdScGRpQmpiR0Z6Y3owaVl5SWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6RTVPVGt2ZUdoMGJXd2lQanhrYVhZZ1kyeGhjM005SW1KcGJ5SStKbXgwT3labmREc21Jek01T3laeGRXOTBPeVpoYlhBN1hDOEtEUWtJRER3dlpHbDJQand2WkdsMlBqd3ZabTl5WldsbmJrOWlhbVZqZEQ0OEwzTjJaejQ9In0="
        );
        assertEq(
            svgB64,
            "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0MDAgMjAwIj48c3R5bGU+LmN7ZGlzcGxheTpmbGV4O2FsaWduLWl0ZW1zOmNlbnRlcjtqdXN0aWZ5LWNvbnRlbnQ6Y2VudGVyO2hlaWdodDoxMDAlO30uYmlve2ZvbnQtZmFtaWx5OnNhbnMtc2VyaWY7Zm9udC1zaXplOjEycHg7bWF4LXdpZHRoOjM0Y2g7bGluZS1oZWlnaHQ6MjBweDtoeXBoZW5zOmF1dG87fTwvc3R5bGU+PGZvcmVpZ25PYmplY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSI+PGRpdiBjbGFzcz0iYyIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGh0bWwiPjxkaXYgY2xhc3M9ImJpbyI+Jmx0OyZndDsmIzM5OyZxdW90OyZhbXA7XC8KDQkIDDwvZGl2PjwvZGl2PjwvZm9yZWlnbk9iamVjdD48L3N2Zz4="
        );
    }

    function testStringWithEmojis() public {
        string memory text = unicode"012345678901234567890123456789012345678👨‍👩‍👧‍👧";
        uint256 len = bytes(text).length;
        assertEq(len, 64);
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        console.log(uri);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        assertEq(
            uri,
            "data:application/json;base64,eyJuYW1lIjogIkJpbyAjMSIsICJkZXNjcmlwdGlvbiI6ICIwMTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzjwn5Go4oCN8J+RqeKAjfCfkafigI3wn5GnIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjRiV3h1Y3owaWFIUjBjRG92TDNkM2R5NTNNeTV2Y21jdk1qQXdNQzl6ZG1jaUlIWnBaWGRDYjNnOUlqQWdNQ0EwTURBZ01qQXdJajQ4YzNSNWJHVStMbU43WkdsemNHeGhlVHBtYkdWNE8yRnNhV2R1TFdsMFpXMXpPbU5sYm5SbGNqdHFkWE4wYVdaNUxXTnZiblJsYm5RNlkyVnVkR1Z5TzJobGFXZG9kRG94TURBbE8zMHVZbWx2ZTJadmJuUXRabUZ0YVd4NU9uTmhibk10YzJWeWFXWTdabTl1ZEMxemFYcGxPakV5Y0hnN2JXRjRMWGRwWkhSb09qTTBZMmc3YkdsdVpTMW9aV2xuYUhRNk1qQndlRHRvZVhCb1pXNXpPbUYxZEc4N2ZUd3ZjM1I1YkdVK1BHWnZjbVZwWjI1UFltcGxZM1FnZDJsa2RHZzlJakV3TUNVaUlHaGxhV2RvZEQwaU1UQXdKU0krUEdScGRpQmpiR0Z6Y3owaVl5SWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6RTVPVGt2ZUdoMGJXd2lQanhrYVhZZ1kyeGhjM005SW1KcGJ5SStNREV5TXpRMU5qYzRPVEF4TWpNME5UWTNPRGt3TVRJek5EVTJOemc1TURFeU16UTFOamM0OEorUnFPS0FqZkNma2FuaWdJM3duNUduNG9DTjhKK1Jwend2WkdsMlBqd3ZaR2wyUGp3dlptOXlaV2xuYms5aWFtVmpkRDQ4TDNOMlp6ND0ifQ=="
        );
        assertEq(
            svg,
            unicode'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><style>.c{display:flex;align-items:center;justify-content:center;height:100%;}.bio{font-family:sans-serif;font-size:12px;max-width:34ch;line-height:20px;hyphens:auto;}</style><foreignObject width="100%" height="100%"><div class="c" xmlns="http://www.w3.org/1999/xhtml"><div class="bio">012345678901234567890123456789012345678👨‍👩‍👧‍👧</div></div></foreignObject></svg>'
        );
    }

    function testEmojiAtBoundaries2() public {
        string memory text = unicode"012345678901234567890123456789012345678👍🏿";
        uint256 len = bytes(text).length;
        assertEq(len, 47);
        bio.mint(text);
        uint256 tokenId = bio.numMinted();
        string memory uri = bio.tokenURI(tokenId);
        string memory json = string(Base64.decode(slice(uri, 29, bytes(uri).length)));
        string memory svg = string(Base64.decode(slice(json, 74 + bytes(text).length, bytes(json).length - 2)));
        assertEq(
            uri,
            "data:application/json;base64,eyJuYW1lIjogIkJpbyAjMSIsICJkZXNjcmlwdGlvbiI6ICIwMTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzjwn5GN8J+PvyIsICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUI0Yld4dWN6MGlhSFIwY0RvdkwzZDNkeTUzTXk1dmNtY3ZNakF3TUM5emRtY2lJSFpwWlhkQ2IzZzlJakFnTUNBME1EQWdNakF3SWo0OGMzUjViR1UrTG1ON1pHbHpjR3hoZVRwbWJHVjRPMkZzYVdkdUxXbDBaVzF6T21ObGJuUmxjanRxZFhOMGFXWjVMV052Ym5SbGJuUTZZMlZ1ZEdWeU8yaGxhV2RvZERveE1EQWxPMzB1WW1sdmUyWnZiblF0Wm1GdGFXeDVPbk5oYm5NdGMyVnlhV1k3Wm05dWRDMXphWHBsT2pFeWNIZzdiV0Y0TFhkcFpIUm9Pak0wWTJnN2JHbHVaUzFvWldsbmFIUTZNakJ3ZUR0b2VYQm9aVzV6T21GMWRHODdmVHd2YzNSNWJHVStQR1p2Y21WcFoyNVBZbXBsWTNRZ2QybGtkR2c5SWpFd01DVWlJR2hsYVdkb2REMGlNVEF3SlNJK1BHUnBkaUJqYkdGemN6MGlZeUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5MekU1T1RrdmVHaDBiV3dpUGp4a2FYWWdZMnhoYzNNOUltSnBieUkrTURFeU16UTFOamM0T1RBeE1qTTBOVFkzT0Rrd01USXpORFUyTnpnNU1ERXlNelExTmpjNDhKK1JqZkNmajc4OEwyUnBkajQ4TDJScGRqNDhMMlp2Y21WcFoyNVBZbXBsWTNRK1BDOXpkbWMrIn0="
        );
        assertEq(
            svg,
            unicode'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><style>.c{display:flex;align-items:center;justify-content:center;height:100%;}.bio{font-family:sans-serif;font-size:12px;max-width:34ch;line-height:20px;hyphens:auto;}</style><foreignObject width="100%" height="100%"><div class="c" xmlns="http://www.w3.org/1999/xhtml"><div class="bio">012345678901234567890123456789012345678👍🏿</div></div></foreignObject></svg>'
        );
    }

    function testRevertOver200() public {
        string
            memory text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        uint256 len = bytes(text).length;
        assertGt(len, 200);
        vm.expectRevert(abi.encodeWithSelector(InvalidBioLength.selector, len));
        bio.mint(text);
    }

    function testRevertLen0() public {
        string memory text = "";
        uint256 len = bytes(text).length;
        assertEq(len, 0);
        vm.expectRevert(abi.encodeWithSelector(InvalidBioLength.selector, len));
        bio.mint(text);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {FHE} from "@fhevm/solidity/lib/FHE.sol";
import {euint32} from "@fhevm/solidity/lib/FHE.sol";

// social network with encrypted posts
contract SocialNetwork is ZamaEthereumConfig {
    using FHE for euint32;
    struct Post {
        address author;
        euint32 content;      // encrypted post content
        uint256 timestamp;
        euint32 likes;        // encrypted like count
        bool visible;
    }
    
    struct Comment {
        address author;
        euint32 content;
        uint256 timestamp;
    }
    
    mapping(uint256 => Post) public posts;
    mapping(uint256 => Comment[]) public comments;
    mapping(address => uint256[]) public userPosts;
    mapping(address => address[]) public friends;
    uint256 public postCounter;
    
    event PostCreated(uint256 indexed postId, address author);
    event PostLiked(uint256 indexed postId);
    event CommentAdded(uint256 indexed postId, address author);
    
    function createPost(euint32 encryptedContent) external returns (uint256 postId) {
        postId = postCounter++;
        posts[postId] = Post({
            author: msg.sender,
            content: encryptedContent,
            timestamp: block.timestamp,
            likes: FHE.asEuint32(0),
            visible: true
        });
        
        userPosts[msg.sender].push(postId);
        emit PostCreated(postId, msg.sender);
    }
    
    function likePost(uint256 postId) external {
        Post storage post = posts[postId];
        require(post.visible, "Post not visible");
        
        // increment encrypted like count
        post.likes = post.likes.add(FHE.asEuint32(1));
        emit PostLiked(postId);
    }
    
    function addComment(uint256 postId, euint32 encryptedComment) external {
        Post storage post = posts[postId];
        require(post.visible, "Post not visible");
        
        comments[postId].push(Comment({
            author: msg.sender,
            content: encryptedComment,
            timestamp: block.timestamp
        }));
        
        emit CommentAdded(postId, msg.sender);
    }
    
    function addFriend(address friend) external {
        // check if already friends
        for (uint256 i = 0; i < friends[msg.sender].length; i++) {
            if (friends[msg.sender][i] == friend) {
                return;
            }
        }
        friends[msg.sender].push(friend);
    }
}


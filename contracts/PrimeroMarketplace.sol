// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PrimeroMarketplace is ERC1155 {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    Counters.Counter private _courseNFTIds; //This is the count of all courses by their ID
    Counters.Counter private _coursesSold; //This is the count of all courses sold
    uint256 public listingPrice = 0.0325 ether; //incase of resell, standard price
    EnumerableSet.UintSet private _coursesUnSold; // all ids this contract holds that have not been set for sale
    mapping(uint256 => uint256) public tokensHeldBalances; // id => balance (amount held not for sale)
    EnumerableSet.UintSet private _studentId;
    Counters.Counter private _studentIds; 

    constructor() ERC1155("") {}

    struct Course {
        uint256 courseNFTId; //auto incremental course Id
        address payable seller; //instructor
        address payable owner; //primero's deployed contract
        address[] buyer; // list of students who buy the course
        uint256 price; //cost of course
        uint256 amount;
        bool sold;
    }

    struct Student {
        address student;
        Course courses;
    }


    mapping(uint256 => Course) private idToCourse;
    mapping(address => Student) public idToStudent;

    event CourseItemCreated(
        uint256 courseNFTId,
        address seller,
        address owner,
        uint256 price,
        uint256 amount,
        bool sold
    );

     event StudentCoursesCreated(
        address student,
        Course courseId
    );

    Course[] private coursesArray; // courses in an array
    Student[] private studentCoursesArray; // students in an array
    Student private student;
    Course private course;
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //fetches all courses 
    function fetchAllCourses() public view returns (Course[] memory) {
        return coursesArray;
    }

    //fetches all students mapped with their courses
    function fetchStudentsCourses() public view returns (Student memory) {
        return idToStudent[msg.sender];
    }

    /* Mints a course and lists it in the marketplace */
    /* amount is the number of students you want enrolled*/
    function listCourse(
        uint256 amount,
        uint256 price,
        bytes memory data
    ) public payable returns (uint256) {
        _courseNFTIds.increment();
        uint256 newcourseNFTId = _courseNFTIds.current();

        _mint(msg.sender, newcourseNFTId, amount, data);
        createCourse(newcourseNFTId, price, amount);
        return newcourseNFTId;
    }

    function createCourse(
        uint256 courseNFTId,
        uint256 price,
        uint256 amount
    ) private {
        address[] memory buyer;
        require(price > 0, "You cant list a free course 1wei >");
        require(msg.value > listingPrice, "Insufficient Funds"); //Wallet balance must be greater than the listing price
        require(
            price * 1 ether > listingPrice,
            "You can't list a course less than the listing price"
        ); //Price must be greater than the listing price

        idToCourse[courseNFTId] = Course(
            courseNFTId,
            payable(msg.sender),
            payable(address(this)),
            buyer,
            price * 1 ether,
            amount,
            false
        );

        emit CourseItemCreated(
            courseNFTId,
            msg.sender,
            address(this),
            price,
            amount,
            false
        );
        coursesArray.push(idToCourse[courseNFTId]);
    }

    /* Transfers ownership of the CourseNFT and funds owner */
    function buyCourse(uint256 courseNFTId) public payable {
        uint256 amount = 1; //student can only buy one course at a time
        uint256 coursePrice = idToCourse[courseNFTId].price;
        require(msg.value > coursePrice, "Insufficient funds"); //Wallet Balance must be greater than price

        setApprovalForAll(address(this), true); //approve safe transfer

        _safeTransferFrom(
            idToCourse[courseNFTId].seller,
            msg.sender,
            courseNFTId,
            amount,
            ""
        ); //transfer ownership to student
        idToCourse[courseNFTId].owner = payable(msg.sender);
        _coursesSold.increment();
        onERC1155Received(
            msg.sender,
            idToCourse[courseNFTId].seller,
            courseNFTId,
            amount,
            ""
        );
        payable(idToCourse[courseNFTId].owner).transfer(listingPrice); //send funds to primero
        payable(idToCourse[courseNFTId].seller).transfer(
            idToCourse[courseNFTId].price
        ); //send funds to instructor

        idToCourse[courseNFTId].buyer.push(msg.sender); // push buyer/students details to course mapping
        coursesArray[courseNFTId - 1].buyer.push(msg.sender); // push buyer/student details to course array that we will be making calls to
        coursesArray[courseNFTId - 1].amount = balanceOf(
            idToCourse[courseNFTId].seller,
            courseNFTId
        );

         idToStudent[msg.sender] = Student(
            payable(msg.sender),
            idToCourse[courseNFTId]
        );

        emit StudentCoursesCreated(
            msg.sender,
            idToCourse[courseNFTId]
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function setURI(string memory newuri) private {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }
}

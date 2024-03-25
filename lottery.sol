// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

import "contracts/CommitReveal.sol" ;


contract Lottery is CommitReveal{
    struct Player {
        address addr; 
        uint legalnumber; // time stamp
        uint choice; // 0 - 999
        uint commiting; // 1 เปิด 0 ปิด
        uint legal; // 1 ผิด 0 ผ่าน
    }

    uint public round ;
    uint public T1 ;
    uint public T2 ;
    uint public T3 ;
    uint public N ;   
    uint public numPlayer;
    uint public startstade;
    uint public stade = 1 ;
    uint public count = 0 ;
    uint public legalPlayer = 0;
    
    uint public coin ; // เงินรางวัลที่จะได้
    address payable contractOwner; // คนเปิดหัว

    
    mapping(uint=>Player) public player ;
    mapping(address => uint) public addrtoplayer;

    constructor(uint _T1, uint _T2, uint _T3, uint _N) {
      T1 = _T1;
      T2 = _T2+T1;
      T3 = _T3+T2;
      N = _N;
      startstade = block.timestamp+T3+1000  ;
      numPlayer = 0;
      contractOwner = payable(msg.sender);
    } // contract เป็นคนกำหนดค่า


    modifier checkStageTransition12() {
      if (stade == 1 && block.timestamp >= startstade + T1 ) {
        stade = 2;
      }
      _;
    }

    modifier checkStageTransition23() {
      if (stade == 1 && block.timestamp >= startstade + T1 ) {
        stade = 2;
      }
      
      if (stade == 2 && block.timestamp >= startstade + T2) {
        stade = 3;
      }
      _;
    }

    modifier checkStageTransition34() {
      if (stade == 2 && block.timestamp >= startstade + T2) {
        stade = 3;
      }
     
     if (stade == 3 && block.timestamp >= startstade + T3) {
        stade = 4;
      }
      _;
    }

    function stade1 (uint choice) public payable checkStageTransition12{
        require(stade == 1 , "Wrong stade" );
        require(numPlayer < N,"Player overlimit"); // เกินจำนวน
        require(msg.sender != contractOwner, "you are contractOwner!"); // คนเปิดห้ามลงทะเบียน

        for (uint i = 0; i <= numPlayer; i++) {
            require( player[i].addr != msg.sender,"you are alredysigh in"); // กันการลงซ้ำ
        } 
        
        require(msg.value == 1000000000000000 wei,"you need to pay 0.001 eth only"); //กันการลงเกิน
        
        coin += 1000000000000000 wei;
        addrtoplayer[msg.sender] = numPlayer;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].legalnumber = N+1;
        player[numPlayer].choice = choice;        
        player[numPlayer].commiting = 1;// คอมมิดทันที
        player[numPlayer].legal = 1;

        require(choice > 0 && choice < 999,"choice in len 0-999"); // กันการลงที่ผิดกฎ
        if (numPlayer == 0 ) {
               startstade = block.timestamp; 
        }


        bytes32 hashChoice = getHash(bytes32(player[numPlayer].choice));
        commit(hashChoice);
        numPlayer++; 

    }

    function stade2(uint _choice) public checkStageTransition23 {
        require(stade == 2 , "Wrong stade");
        uint idx = addrtoplayer[msg.sender];
        require(player[idx].addr == msg.sender, "you are not in system") ; //กันการมั่ว เเต่จริงๆก็ไม่จำเป็น
        require(player[idx].commiting == 1 , "need to commit"); //กันการไม่คอมมิด
        
        reveal(bytes32(_choice));
        player[idx].choice = _choice ;
        player[idx].legal = 0; 
        
    }



    function stade3() public payable checkStageTransition34 {
      require(stade == 3, "Wrong stade"); 
      require(msg.sender == contractOwner, "you are not contractOwner"); // ตยสร้างคนเดียวที่เปิดได้
      require(round == 0 , "cant use this stade again"); // ใช้ได้เเค่ครั้งเดียว
      uint result = 0 ;
      round++ ;

      for (uint i = 0; i <= numPlayer; i++) {
          if (player[i].legal == 0 && player[i].commiting == 1) {
                  result = result ^ player[i].choice; // xor
                  player[i].legalnumber = legalPlayer ; // อันดับที่ถูกต้อง
                  legalPlayer++;
                   
          }
      } 

      if (legalPlayer==0) { // คอนเเทร็กกินเรียบ
          //T2 = 1 ;
          contractOwner.transfer(coin);
          coin = 0;

      }

      else {//กรณีที่มีคนได้
          
          //uint hash = uint(keccak256(abi.encodePacked(result)));
          //uint winnerNumber =  hash % legalPlayer  ;
          uint winnerNumber = result % legalPlayer ; // ไม่เเน่ใจว่าวิธีไหน
          //T1 = winnerNumber ;
        
          for(uint i = 0 ; i < N ; i++){
            if(player[i].legalnumber == winnerNumber){
                address payable chamAddr = payable(player[i].addr);
                chamAddr.transfer(coin * 98 / 100 );
                break ;
            }
          }
            
          contractOwner.transfer(coin * 2 / 100 ); //ส่วนเเบ่ง
          coin = 0;

        }

          for (uint i; i < numPlayer; i++) {
            player[i].legal = 2;
          }
        
    }

    function stade4() public payable checkStageTransition34{
      require(stade == 4 , "Not in time");
      uint idx = addrtoplayer[msg.sender];
      require(player[idx].legal == 0 || player[idx].legal == 1, "wromg");
      require(player[idx].addr == msg.sender, "not in system");
      //require(player[idx].legal == 0, "ilegal !")
      
      player[idx].legal = 2 ; //เปลี่ยนไม่ให้ใช้งานได้อีกครั้ง
      address payable addr = payable(player[idx].addr);
      addr.transfer(1000000000000000 wei);
    }
}

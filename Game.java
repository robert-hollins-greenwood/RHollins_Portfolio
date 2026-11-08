package game;
import java.util.*;
public class Game {
	private Scanner scanner = new Scanner(System.in);
	private Stack<Room> roomHistory = new Stack<>();//stacks each room you have visited
	private Deque<String> inventory = new ArrayDeque<>();//deque your inventory to remove from both ends
	private boolean running = true;//if the console is running keep true
	private int materia = 0;//track materia count
	private int runCount = 0;//track run count
	private boolean keyUsed = false;//check if key used
	private boolean bossDefeated = false;//check boss defeated
	
	
	public void start() {
		System.out.println("===First Fantasy(let's hope square enix has a sense of humor and doesn't sue me)===");//set title
		Room currentRoom = Room.getRandomRoom();//give random room
		roomHistory.push(currentRoom);//push to top of stack
		while(running) {
			System.out.println("\n" + currentRoom.getDescription());
			System.out.println("Enemies: " + currentRoom.getEnemyNames());
			System.out.println("Inventory: " + inventory);
			System.out.println("Items: " + currentRoom.getItems());
			System.out.println("\nCommands: attack, move ,run, take<item>, use<item>, quit");
			String input = scanner.nextLine().trim();
			System.out.print("> ");
			
			switch(input.split(" ")[0]) {//track input of substring
			case "move":
				currentRoom = Room.getRandomRoom();
				roomHistory.push(currentRoom);
				System.out.println("You enter: " + currentRoom.getDescription());
				System.out.println("Enemies: " + currentRoom.getEnemies());
				System.out.println("Items in room:" + currentRoom.getItems());
				checkEndings(currentRoom);
				break;
			case "attack":
				if(!currentRoom.getEnemies().isEmpty()) {//if room has enemies defeat them change queue if boss change true check endings
					Enemy defeated = currentRoom.fightNextEnemy();
					System.out.println("You defeated: " + defeated.getName());
					if(defeated.getName().equals("Dungeon Boss"))
					bossDefeated = true;
					
				}else {//if empty
					System.out.println("No enemies to attack");
				}
			checkEndings(currentRoom);
			break;
			case "take"://take item make sure user input is above 5 characters if it has item add to last of deque and remove from the item from room
				String item = input.substring(5).trim();
				if(currentRoom.getItems().contains(item)) {
					inventory.addLast(item);
					currentRoom.removeItems(item);
					System.out.println("You picked up: " + item);
					if(item.equals("Materia")) materia++;//for ending
				}else {
					System.out.println("No items to retrieve");//if empty
				}
				checkEndings(currentRoom);
				break;
			case "run":
				if(!roomHistory.isEmpty()) {//go to previous room by popping from the current stack and reading previous room as top
					currentRoom = roomHistory.pop();
					runCount++;//track for ending
					System.out.println("You return to: " + currentRoom.getDescription());
				}else {
					System.out.println("You can't run back further");//if first room
				}
				checkEndings(currentRoom);
				break;
			case "use":
				String useItem = input.substring(4).trim();//use item input
				if(!inventory.contains(useItem)) {
					System.out.println("You don't have that item");//if empty
					break;
				
				}
				switch(useItem) {
				case "Potion":
					if(!currentRoom.getEnemies().isEmpty()) {
						Enemy removed = currentRoom.getEnemies().poll();//potion removes one enemy form battle
						System.out.println("You use a postion it scared off: " + removed.getName());
					}else {
						System.out.println("No enemies to use this potion on");
					}
					inventory.remove(useItem);//remove from inventory
					break;
				case "Phoenix Down"://if phoenix down is used clear all enemies
					if(!currentRoom.getEnemies().isEmpty()) {
						currentRoom.getEnemies().clear();
						System.out.println("A phoenix rises from the ashes and burns all enemies to a crisp");
					}else {
						System.out.println("No enemies to use this phoenix down on.");
					}
					inventory.remove(useItem);
					break;
				case "Key"://ending items
					keyUsed = true;
					System.out.println("You use the key... it feels important");
					inventory.remove(useItem);
					checkEndings(currentRoom);
					break;
				case "Materia":
					System.out.println("The materia glows with power but you struggle to use it");
					break;
				default:
					System.out.println("This item can't be used");
					break;
				
				}
				break;
			case "quit"://quit
				System.out.println("It's a rouge like man you lossed all you're progress");
				break;
				
			}
			
		}
	}
	private void checkEndings(Room currentRoom) {//check endings by all the variable tracking we did in the while loop
		if(runCount >= 5) {
			System.out.println("\nBeing a coward is ok sometimes not all the time. You collapse from exhauston");
			System.out.println("===Coward Ending===");
			running = false;
			return;
		}
		if(currentRoom.getEnemies().size() == 5) {
			System.out.println("\nYeah dawg you're cooked");
			System.out.println("===Overrun Ending===");
			running = false;
			return;
		}
		if(currentRoom.getDescription().contains("Exit Chamber")) {
			if(bossDefeated) {
				System.out.println("\nYou beat the boss the dungeon collapses behind you");
				System.out.println("===Hero Ending===");
			}else if(materia >= 3){
				System.out.println("\nTalk about an explorer. The materia glows and lights your escape path");
				System.out.println("===Nook & Cranny Ending===");
			}
			else if(keyUsed) {
				System.out.println("\n You unlock a strange looking door and exit the dungeon. congrats");
				System.out.println("===Master of Unlocking Ending===");
			}
			
			else {
				System.out.println("\nYou found the exit lucky you");
				System.out.println("===Sheer Luck Ending===");
			}
		}
	}

}
 


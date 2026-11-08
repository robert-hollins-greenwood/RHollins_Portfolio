package game;
import java.util.*;
public class Room {
	private static String [] roomNames = {"The Backrooms", "Malevolent Kitchen", "Seventh Heaven", "Evil Basement", "Harris Dining Hall"};//declares the room names
	private String description;//stores name of room 
	private Queue<Enemy> enemies = new LinkedList<>();//make list of enemies into a queue FIFO system
	private List<String> items = new ArrayList<>();//turns items into an array list
	public Room(String description, List<Enemy> enemies, List<String> items) {//sets up room displaying the name enemies and items
		this.description = "You enter a " + description;//display description of room
		for(Enemy e : enemies) this.enemies.add(e);//add enemies to queue
		this.items = new ArrayList<>(items);//array list of items
	}
	public static Room getRandomRoom() {
		Random random = new Random();//use random function
		String desc = roomNames[random.nextInt(roomNames.length)];//select a random value from the array of room names
		int enemyCount = random.nextInt(5) + 1;//random enemy count from 1-5
		List<Enemy> enemies = new ArrayList<>();
		for(int i = 0; i < enemyCount; i++) {//for the integer picked add enemy
			enemies.add(Enemy.randomEnemy());
		}
		String [] possItems = {"Potion", "Materia", "Phoenix Down", "Key"};//possible items array
		int itemCount = random.nextInt(2) + 1;//pick random integer 1-2
		List<String> roomItems = new ArrayList<>();//for integer picked add item randomly from list
		for(int i = 0; i < itemCount; i++) {
			roomItems.add(possItems[random.nextInt(possItems.length)]);
		}
		if(random.nextInt(12)==0) {//1/12 chance to reach exit
			return new Room("Exit Chamber - you see a light at the end of the tunnel", new ArrayList<>(), new ArrayList<>());
		}
		if(random.nextInt(15)==0) {//1/15 chance to enter boss dungeon
			List<Enemy> bossList = List.of(new Enemy("Dungeon Boss"));//add boss to own list
			return new Room("Boss Battle", bossList, new ArrayList<>());//return the room
		}
		return new Room(desc, enemies, roomItems);
	}
	public String getDescription() {
		return description;
	}
	public Queue<Enemy> getEnemies(){
	return enemies;
	
}
	public List<String> getItems(){
		return items;
	}
	public List<String> getEnemyNames(){
		List<String> names = new ArrayList<>();
		for(Enemy e : enemies) names.add(e.getName());
		return names;
	}
	public boolean removeItems(String item) {//remove items form inventory
		return items.remove(item);
	}
	public Enemy fightNextEnemy() {// changes the front of the queue once an enemy is removed
		return enemies.poll();
	}
}

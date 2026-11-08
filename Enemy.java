package game;
import java.util.Random;
public class Enemy {
	private String name;
	private static String [] enemyTypes = {"Tonberry", "Chocobo", "Iron Giant", "Dragon Zombie", "Malboro"};//enemy names 
	public Enemy(String name) {
		this.name = name;
	}
	public static Enemy randomEnemy() {
		Random rand = new Random();
		return new Enemy(enemyTypes[rand.nextInt(enemyTypes.length)]);//pick random enemy
	}
	public String getName() {
		return name;
	}
	public String toString() {//debug line to prevent things like enemy@382908382 from displaying 
		return name;
	}

}

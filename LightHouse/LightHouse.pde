// Title: Light House (phare)
// Author: Budulla Akhlaaq
// Je vais aussi remercier mon ami (jean raymond joyvani) pour son aide dans le développement de ce jeu en partie le pour coder.

/*
DOCUMENTATION des librairie utiliser:
www.freesfx.co.uk/soundeffects/drum-and-Bass/                                    //son du jeux
https://www.youtube.com/user/shiffman                                          //chaine youtube sous le nom de the code train qui explique les function ci desous.
https://www.youtube.com/channel/UC5dMacit2C5fYiS4lMNq3ow
https://forum.processing.org/one/topic/menu-for-a-game.html                   //switch
https://forum.processing.org/two/discussion/20777/changing-screen-with-mouse-click  //menu clickable
https://processing.org/reference/PGraphics.html
https://processing.org/reference/ArrayList.html
https://github.com/processing-js/processing-js/issues/149                     //aider pour creer le masque dimage au click gauche
https://processing.org/reference/colorMode_.html
https://processing.org/reference/frameRate_.html
https://processing.org/reference/rectMode_.html                             //pour la redimention
https://processing.org/reference/popMatrix_.html                           // matrix stack
https://forum.processing.org/two/discussion/150/gradient-color-effect       //pour le gradient de couleur
https://processing.org/reference/translate_.html
https://processing.org/reference/loadPixels_.html
http://py.processing.org/reference/dict_update.html
https://processing.org/reference/PGraphics_beginDraw_.html
https://processing.org/reference/PGraphics_endDraw_.html
https://processing.org/reference/updatePixels_.html
*/

import ddf.minim.*;
private final static float IDEAL_FRAME_RATE = 30f;


Minim minim;
AudioPlayer song;

PImage startImage;
PImage controle;
PImage highscores;
PImage pauseds;
PImage surfaceWorldImage, hiddenWorldImage;
PGraphics surfaceWorldGraphics;
PGraphics maskGraphics;

float windowSize;
final float maxWindowSize = 240f;

float damageValue;
final float maxDamageValue = 15f;

float generationProbability = 0.015f * 60f / IDEAL_FRAME_RATE;
int destroyedSquareCount, missedSquareCount, mistakeCount;
boolean pause;

int highscore;

//pour le switch case
int state = 0; //The current state
final int menu = 0;
final int control = 1;
final int jouer = 2;
final int highScore = 3;

//instantier les tableau pour stocker les carre
final ArrayList<ClickableSquare> clickableSquareList = new ArrayList<ClickableSquare>(256);
final ArrayList<EffectSquare> effectSquareList = new ArrayList<EffectSquare>(256);
final ArrayList<Square> deadSquareList = new ArrayList<Square>(256);


void setup() {
  size(640, 640);
  smooth();
  frameRate(IDEAL_FRAME_RATE);
  colorMode(HSB, 360f, 100f, 100f, 100f);
  noFill();
  strokeWeight(1f);
  textSize(16f);
  
  //pour charger la music
  minim = new Minim(this);
  song = minim.loadFile("sound.mp3");
  song.loop();
  song.play();
  
  startImage = loadImage("start.png");
  controle = loadImage("control.png");
  highscores = loadImage("highscore.png");
  pauseds = loadImage("pause.png");
  surfaceWorldImage = loadImage("dark.jpg");
  hiddenWorldImage = loadImage("green.jpg");
  maskGraphics = createGraphics(width, height);
  surfaceWorldGraphics = createGraphics(width, height);

}

void draw() {
  //println(mouseX + " : " + mouseY); //<---------debugging
  
  switch(state) {
  case menu:
    image(startImage, 0, 0);
    break;
    
  case control:
    image(controle,0,0);
    break;
  
  case highScore:
    image(highscores,0,0);
    break;
    
  case jouer:
  float yOffsetPosition;
  if (damageValue > 0f) yOffsetPosition = 0.5f * random(-damageValue, damageValue);
  else yOffsetPosition = 0f;

//pour appeller le scanner en clickant droit
  if (mousePressed && mouseButton == RIGHT) windowSize += (maxWindowSize - windowSize) * 0.02f;
  else windowSize = max(windowSize - 8f, 0f);

  // prepare le monde
  image(hiddenWorldImage, 0f, yOffsetPosition);
  surfaceWorldGraphics.beginDraw();
  surfaceWorldGraphics.image(surfaceWorldImage, 0f, 0f);
  surfaceWorldGraphics.endDraw();

  // mettre à jour et dessiner des carrés cliquables
  rectMode(CENTER);
  for (ClickableSquare eachClickableSquare : clickableSquareList) {
    eachClickableSquare.update();
    eachClickableSquare.display();
    surfaceWorldGraphics.beginDraw();
    surfaceWorldGraphics.rectMode(CENTER);
    eachClickableSquare.displayPretending(surfaceWorldGraphics);
    surfaceWorldGraphics.endDraw();
  }

  // Affichage du monde
  if (windowSize > 0f) {
    maskGraphics.beginDraw();
    maskGraphics.noStroke();
    maskGraphics.fill(255f);
    maskGraphics.rectMode(CORNER);
    maskGraphics.rect(0f, 0f, width, height);
    if (windowSize > 0f) {
      maskGraphics.fill(0f);
      maskGraphics.rectMode(CENTER);
      maskGraphics.pushMatrix();
      maskGraphics.translate(mouseX, mouseY);
      maskGraphics.rotate(0.05f * TWO_PI * frameCount / IDEAL_FRAME_RATE);
      maskGraphics.rect(0f, 0f, windowSize * random(0.98f, 1.02f), windowSize * random(0.98f, 1.02f));
      maskGraphics.popMatrix();
    }
    maskGraphics.endDraw();
    alternateMask(surfaceWorldGraphics, maskGraphics);
  }
  image(surfaceWorldGraphics, 0f, yOffsetPosition);

  // mettre à jour et dessiner des carrés d'effet
  rectMode(CENTER);
  for (EffectSquare eachEffectSquare : effectSquareList) {
    eachEffectSquare.update();
    eachEffectSquare.display();
  }

  // erreur d'effet
  if (damageValue > 0f) {
    rectMode(CORNER);
    noStroke();
    fill(0f, 100f, 100f, 50f * damageValue / maxDamageValue);
    rect(0f, 0f, width, height);
    damageValue -= 1f * IDEAL_FRAME_RATE / 60f;
    if (damageValue < 0f) damageValue = 0f;
  }

  // information du jeu
  fill(0f, 0f, 100f);
  noStroke();
  text("Détruit:", 20f, 20f);
  displayCount(110f, 20f, destroyedSquareCount);
  text("Manqué:", 20f, 40f);
  displayCount(110f, 40f, missedSquareCount);
  text("Mauvaise:", 20f, 60f);
  displayCount(110f, 60f, mistakeCount);
  text("Frame rate:", 20f, 80f);
  text("" + round(frameRate) + " fps", 110f, 80f);

  // tuer et générer des carrés
  if (deadSquareList.size() >= 1) {
    clickableSquareList.removeAll(deadSquareList);
    effectSquareList.removeAll(deadSquareList);
    deadSquareList.clear();
  }
  if (random(1f) < generationProbability) {
    final boolean black = (random(1f) < 0.3f);
    clickableSquareList.add(new ClickableSquare(random(width * 0.1f, width * 0.9f), -50f, color(random(360f), 100f, 100f), black));
  }
  }
  
  }



void highscore(){
  
    }



void mousePressed() {
    if(state == menu){
      if (mouseY >= 371 && mouseY <= 417 && mouseX >= 218 && mouseX <= 417){
            state = jouer;
         }
        }
        if(state == menu){
          if(mouseY >= 450 && mouseY <= 501 && mouseX >= 220 && mouseX <= 418){
              state=control;
          }
        }
        
        if(state == control){
          if(mouseY >= 11 && mouseY <=65  && mouseX >= 16 && mouseX <= 72){
              state=menu;
          }
        }
        
        if(state == menu){
          if(mouseY >= 527 && mouseY <= 576 && mouseX >= 223 && mouseX <= 418){
              state=highScore;
          }
        }
        
        if(state == menu){
          if(mouseY >= 7 && mouseY <= 46 && mouseX >= 6 && mouseX <= 51 ){
            if(song.isPlaying()) song.pause();  
            else{ 
            song.rewind(); 
          song.play();
          }
        }
        }
        
        
        if(state == highScore){
          if(mouseY >= 11 && mouseY <=65  && mouseX >= 16 && mouseX <= 72){
              state=menu;
          }
        }
        if (mouseButton == RIGHT) return;
        for (ClickableSquare eachClickableSquare : clickableSquareList) {
            if (eachClickableSquare.isMouseOvered() == false) continue;

              color effectColor;
            if (eachClickableSquare.isBlack) {
              destroyedSquareCount++;
              generationProbability += 0.001f * IDEAL_FRAME_RATE / 60f;
              effectColor = color(0f, 0f, 100f);
              } else {
              mistakeCount++;
              damageValue = maxDamageValue;
              effectColor = color(0f, 100f, 80f);
              }
                
                // générer des carrés d'effet
                  for (int i = 0; i < 32; i++) {
                  effectSquareList.add(new EffectSquare(eachClickableSquare.xPosition, eachClickableSquare.yPosition, effectColor));
                  }
                  deadSquareList.add(eachClickableSquare);
                  break;
                  }
            }



void keyPressed() {
                   
  if (key == 's') { // demarer le jeux
    state = jouer;
  }
  
  if(key=='c'){     //entre en dans control
    state = control;
  }
  if(key=='r'){      //utiliser 1 pour sortir de la fenetre et retourner au menu principale
    state = menu;
  }
  if(key=='h'){
    state=highScore;
  }
  
  if (key == ' ') {    //utilisez la barre d'espace pour mettre le jeu en pause et de meme pour reprendre le jeux 
    if (pause == true){
        loop();
    }
    else {
      noLoop();
      image(pauseds,0,0);
    }
    pause = !pause;
  }
}

void displayCount(float x, float y, int count) {
  float xPosition = x;
  float yPosition = y - 14f;
  rectMode(CORNER);
  for (int i = 0; i < count; i++) {
    rect(xPosition, yPosition, 6f, 14f);
    xPosition += 8f;
    if (i % 5 == 4) xPosition += 4f;
  }
}



abstract class Square
{
  final float displaySize;
  final int lifespanFrameCount;
  final color squareColor;
  final float rotationVelocity;
  
  float xPosition, yPosition;
  float rotationAngle;
  int properFrameCount;

  Square(float x, float y, color col, int lifespan, float sz, float rotVel) {
    xPosition = x;
    yPosition = y;
    squareColor = col;

    lifespanFrameCount = lifespan;
    displaySize = sz;
    rotationVelocity = rotVel * TWO_PI / IDEAL_FRAME_RATE;
  }

  void update() {
    yPosition += 1f * 60f / IDEAL_FRAME_RATE;
    rotationAngle += rotationVelocity;
    properFrameCount++;
  }
  
  abstract void display();
}

//cette classe est utilisée pour créer un  les carré cliquable
final class ClickableSquare
  extends Square
{
  final boolean isBlack;

  ClickableSquare(float x, float y, color col, boolean black) {
    super(x, y, col, -1, 32f, 0.2f);
    isBlack = black;
  }

//verifie si la souris et sur le carré
  boolean isMouseOvered() {
    return (dist(mouseX, mouseY, xPosition, yPosition) < displaySize * 0.8f);
  }

/*
la fonction de update met à jour le carré et si l'utilisateur 
a raté un carré et qu'il est passé à l'écran, 
le carré manqué est incrémenté
*/
  void update() {
    super.update();
    if (yPosition > height + displaySize) {
      if (this.isBlack) missedSquareCount++;
      deadSquareList.add(this);
      }
  }



  void display() {
    if (this.isBlack) return;
    pushMatrix();
    translate(xPosition, yPosition);
    rotate(rotationAngle);
    stroke(squareColor, 80f);
    fill(squareColor, 50f);
    rect(0f, 0f, displaySize, displaySize);
    popMatrix();
  }



  void displayPretending(PGraphics g) {
    g.pushMatrix();
    g.translate(xPosition, yPosition);
    g.rotate(rotationAngle);
    g.stroke(192f);
    g.fill(0f, 128f);
    g.rect(0f, 0f, displaySize, displaySize);
    g.popMatrix();
  }
}



final class EffectSquare
  extends Square
{
  final float xVelocity, yVelocity;

  EffectSquare(float x, float y, color col) {
    super(x, y, col, 30, 16f, 1f);

    final float directionAngle = random(TWO_PI);//TWO_PI est une constante mathématique avec la valeur 6.2831855. C'est deux fois le rapport de la circonférence d'un cercle à son diamètre.
    final float speed = random(0.5f, 5f) * 60f / IDEAL_FRAME_RATE;
    xVelocity = speed * cos(directionAngle);
    yVelocity = speed * sin(directionAngle);
  }

  void update() {
    super.update();
    xPosition += xVelocity;
    yPosition += yVelocity;
    if (properFrameCount == lifespanFrameCount) deadSquareList.add(this);
  }
/*
--->push/popMatrix();
La fonction pushMatrix () enregistre les coordonnées actuel du système dans la pile et popMatrix () 
restaure le système de coordonnées précédent. pushMatrix () et popMatrix () sont utilisées en conjonction 
avec les autres fonctions de transformation et peuvent être intégrées pour contrôler l'étendue des transformations.

--->rotate();
Fait pivoter la quantité spécifiée par le paramètre angle.

--->translate();
Spécifie une quantité pour déplacer les objets dans la fenêtre d'affichage.
Le paramètre x spécifie la translation gauche / droite, le paramètre y spécifie 
la conversion haut / bas et le paramètre z spécifie les translations vers / à 
l'écart de l'écran.
*/
  void display() {
    pushMatrix();
    translate(xPosition, yPosition);
    rotate(rotationAngle);
    stroke(squareColor, 100f * getFadeRatio());
    noFill();
    rect(0f, 0f, displaySize, displaySize);
    popMatrix();
  }
//contrôle le fondu du scanner
  float getFadeRatio() {
    return max(0f, 1f - (float(properFrameCount) / lifespanFrameCount));
  }
}

//utiliser pour faire le mask sure PImage
void alternateMask(PImage p, PImage m) {
  m.loadPixels();//Charge un instantané de la fenêtre d'affichage actuelle dans le tableau pixels [].
  p.loadPixels();
  for (int j=p.width*p.height-1; j >= 0; j--) {
    p.pixels[j] = p.pixels[j] & 0x00FFFFFF |    ((m.pixels[j] & 0x000000FF) << 24);
  }
  p.updatePixels(); //Met à jour la fenêtre d'affichage avec les données du tableau pixels []
  }
void setup() {
   size( 500 , 500 );
   textAlign(CENTER, CENTER);
   textSize( 30 );
   fill( 0 );
}
 
void draw() {
   background( 255 );
   text(myText, 0 , 0 , width, height);
}
 
void keyPressed() {
   if (keyCode == BACKSPACE) {
     if (myText.length() > 0 ) {
       myText = myText.substring( 0 , myText.length()- 1 );
     }
   } else if (keyCode == DELETE) {
     myText = "" ;
   } else if (keyCode != SHIFT && keyCode != CONTROL && keyCode != ALT) {
     myText = myText + key;
   }
}
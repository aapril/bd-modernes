package org.etsmtl.ind500;

import org.etsmtl.ind500.utils.ArrayDisplay;

public class app {
    public static void main(String[] args) {

        exempleDebug();
    }

    public static void exempleDebug(){
        String[][] exemple1 = new String[][] {
                {"1","Joe", "Smith","USA", "10.03"},
                {"2","Jane", "Brown","USA", "130.22"},
                {"3","Luc", "Tremblay","CA", "22.68"},
                {"4","Annie", "Perrault","CA", "15.99"}
            };

        String[][] exemple2 = new String[][] {
                {"5","Toto", "Java","PC LAND", "10.03"},
                {"6","Titi", "Python","Nowhere", "130.22"},
                {"7","Tutu", "Go","Somewhere", "22.68"},
        };
        ArrayDisplay arrayDisplay = new ArrayDisplay(5, 20, true);
        arrayDisplay.setColumnStyle(0, 4, false);
        arrayDisplay.setColumnStyle(3, 12, false);
        arrayDisplay.setColumnStyle(4, 15, false);

        arrayDisplay.setHeaders("id","FirstName","LastName","Country","data1");

        exempleDebugPrintArray(arrayDisplay,exemple1);
        exempleDebugPrintArray(arrayDisplay,exemple2);
    }

    public static void exempleDebugPrintArray(ArrayDisplay arrayDisplay, String[][] data){
        arrayDisplay.printHeader();

        for (String[] line : data) {
            arrayDisplay.printRecord(line);
        }

        arrayDisplay.printFooter();
    }
}

package org.etsmtl.ind500.utils;

public class ArrayDisplay {

    public static class ColumnStyle{
        private final int len;
        private final boolean alignLeft;

        public ColumnStyle(int len, boolean alignLeft){
            this.len = len;
            this.alignLeft = alignLeft;
        };

        public int getLength(){
            return len;
        }

        public boolean getAlignLeft(){
            return alignLeft;
        }

        public String getFormat(){
            return "%"+(alignLeft?"-":"")+len+"s";
        }
    }

    private static final int DEFAULT_COLUMN_SIZE = 20;
    private static final String LINE = "-";
    private static final String SEPARATOR = "|";

    private final int nbColumn;
    private final String[] columnsHeaders;
    private final ColumnStyle[] columnStyles;

    private String fullLine;

    public ArrayDisplay(int nbColumn){
        this(nbColumn, new ColumnStyle(DEFAULT_COLUMN_SIZE, true));
    }

    public ArrayDisplay(int nbColumn, int defaultColumnSize, boolean defaultAlignLeft){
        this(nbColumn, new ColumnStyle(defaultColumnSize, defaultAlignLeft));
    }

    public ArrayDisplay(int nbColumn, ColumnStyle defaultColumnsStyle) {
        this.nbColumn = nbColumn;
        this.fullLine = "";

        this.columnStyles = new ColumnStyle[nbColumn];
        this.columnsHeaders = new String[nbColumn];
        for (int i = 0; i < nbColumn; i++) {
            this.columnsHeaders[i] = "col"+i;
            this.columnStyles[i] = defaultColumnsStyle;
        }
        updateFullLine();
    }

    public void setHeaders(String... titles){
        if(titles.length!=nbColumn){
            throw new IllegalStateException("Titles length is not equal to nbColumn");
        }

        System.arraycopy(titles, 0, columnsHeaders, 0, titles.length);

    }

    public void setColumnsStyle(ColumnStyle... styles){
        if(styles.length!=nbColumn){
            throw new IllegalStateException("Styles length is not equal to nbColumn");
        }

        System.arraycopy(styles, 0, columnStyles, 0, styles.length);
        updateFullLine();
    }

    public void setColumnStyle(int index, ColumnStyle style){
        columnStyles[index] = style;
        updateFullLine();
    }

    public void setColumnStyle(int index, int columnSize, boolean alignLeft){
        setColumnStyle(index, new ColumnStyle(columnSize, alignLeft));
    }

    public void printHeader(){
        printFullLine();
        printRecord(this.columnsHeaders);
        printFullLine();
    }

    public void printRecord(String... values){
        if(values.length!=nbColumn){
            throw new IllegalStateException("Values length is not equal to nbColumn");
        }
        StringBuilder sb = new StringBuilder();

        for (int i = 0; i < nbColumn; i++){
            if(i!=0){sb.append(" ");}
            sb.append(SEPARATOR);
            sb.append(" ");
            sb.append(String.format(columnStyles[i].getFormat(),values[i]));
        }
        sb.append(" ");
        sb.append(SEPARATOR);

        System.out.println(sb);
    }

    public void printFooter(){
        printFullLine();
    }

    private void printFullLine(){
        System.out.println(this.fullLine);
    }

    private void updateFullLine(){
        int len = (columnsHeaders.length)*3+1;
        for(int i=0; i<nbColumn; i++){
            len += columnStyles[i].getLength();
        }
        this.fullLine = LINE.repeat(len);
    }
}

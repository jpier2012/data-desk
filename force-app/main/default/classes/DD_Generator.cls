public class DD_Generator {
    public class Outputs { 
        @InvocableVariable(label='First Name') 
        public String firstName;
        
        @InvocableVariable(label='Last Name')
        public String lastName;
    }

    @InvocableMethod(label='Generate Random Name')
    public static List<Outputs> randomName() {
        String[] name = getRandomName();
        
        Outputs outputs = new Outputs();
        outputs.firstName = name[0];
        outputs.lastName = name[1];
        
        return new Outputs[]{ outputs };
    }
//
// getRandomName
//
    public static String[] getRandomName() {
        // generate random index between 0 and the number of celebrity names - 1
        return celebrityNames[Math.round(Math.random() * (celebrityNames.size() - 1))].split('\\,');
    }
//
// getRandomDate
//
    public static Date getRandomDate(String rangeString){
        String[] range;
        Date startDate, endDate;
        String returnString;
        Integer daysBetween, addDays;
        try {
            range = DD_Util.split(rangeString);
            startDate = Date.valueOf(range[0]);
            endDate = Date.valueOf(range[1]);     
        	daysBetween = startDate.daysBetween(endDate);
            addDays = startDate == endDate ? 0 : Math.round(Math.random() * daysBetween);
            
        } catch(Exception e){
            throw new DataDeskException('Error parsing date parameters : ' + rangeString, e);
        }
        
        return startDate.addDays(addDays);
    }
//
// getRandomDateTime
//
    public static DateTime getRandomDateTime(String rangeString){
        Date randomDate = Date.valueOf(getRandomDate(rangeString));
        DateTime randomDateTime = 
            DateTime.newInstance(
                randomDate.year(), randomDate.month(), randomDate.day(), 
                Math.round(Math.random() * 12), Math.round(Math.random() * 60), 0
            );
        
        return randomDateTime;
    }
//
// getRandomDecimal
//
    public static Decimal getRandomDecimal(Integer min, Integer max, Integer scale) {
        return getRandomDecimal((Long)min, (Long)max, scale);
    }
    
    public static Decimal getRandomDecimal(Long min, Long max, Integer scale) {
        Long multiplier = max - min;
        Decimal randomNumber = (Math.random() * multiplier) + min;
        
        if (scale != null){
        	return randomNumber.setScale(scale);
        } else {
        	return Math.round(randomNumber);
        }
    }
    
    public static Decimal getRandomDecimal(String rangeString) {
        String[] range;
        Integer min, max, scale, multiplier;
        Decimal randomNumber;
        
        try {
            range = DD_Util.split(rangeString);  
            min = Integer.valueOf(range[0]);
            max = Integer.valueOf(range[1]);
            scale = range.size() == 3 ? Integer.valueOf(range[2]) : null;
            return getRandomDecimal(min, max, scale);
        } catch(Exception e){
            throw new DataDeskException('Error calculating random decimal : ' + rangeString, e);
        }
    }
//
// getRandomIndex
//
    public static String getRandomIndex(String[] stringList){
        if (!stringList?.isEmpty()){
        	return stringList[(Integer)getRandomDecimal(0,stringList.size() - 1, 0)];
        } else {
            return null;
        }
    }
//
// castOrGenerateValue
//   
    public static Object getValue(Schema.DescribeFieldResult fieldDescribe, List<String> valueList, Object value){
        
        String 
            dataType = fieldDescribe.getType().name(),
            fieldName = fieldDescribe.getName();
        
        Boolean 
			isNumber = 
				dataType == DD_Util.DISPLAY_TYPE_PERCENT 
				|| dataType == DD_Util.DISPLAY_TYPE_INTEGER 
				|| dataType == DD_Util.DISPLAY_TYPE_DOUBLE 
				|| dataType == DD_Util.DISPLAY_TYPE_CURRENCY,
			isList = 
				dataType == DD_Util.DISPLAY_TYPE_PICKLIST 
				|| dataType == DD_Util.DISPLAY_TYPE_MULTIPICKLIST
				|| dataType == DD_Util.DISPLAY_TYPE_REFERENCE;
        
        try {
            if (isList){
                
                value = value != null ? value : getRandomIndex(valueList);
                return String.valueOf(value);
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_BOOLEAN){
                
                value = value != null ? value : getRandomDecimal(0,1,0);
                return Boolean.valueOf(value);
                
            }else if (dataType == DD_Util.DISPLAY_TYPE_DATE){
                
                return value != null ? Date.valueOf('' + value) : getRandomDate(valueList[0]);
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_DATETIME){
                
                return value != null ? DateTime.valueOf('' + value) : getRandomDateTime(valueList[0]);
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_PHONE){
                
                value = value != null ? value : getRandomDecimal(10000000000L,19999999999L,0);
                return String.valueOf(value);
                
			} else if (isNumber){
                
                value = value != null ? value : getRandomDecimal(valueList[0]);
                
                if (dataType == DD_Util.DISPLAY_TYPE_INTEGER){
                    return Integer.valueOf(value);
                } else if (dataType == DD_Util.DISPLAY_TYPE_DOUBLE 
                           || dataType == DD_Util.DISPLAY_TYPE_CURRENCY){
                	return Double.valueOf(value);
                } else {
                	return (Decimal)value; 
                }               
                
            }
        } catch(Exception e){
            throw new DataDeskException('Error casting or generating value : ' + fieldName + ' : ' + value, e);
        }
        
        return value;
    }

    public static String getMergedValue(sObject record, String input){
        String output = input;
        for (String match : getMergeFields(output)){
            try {
                switch on match {
                    when 'DATE' {
                        output = output.replace('[[DATE]]', '' + Date.today());
                    }
                    when 'TIME' {
                        output = output.replace('[[TIME]]', DateTime.now().format('hh:mm:ss'));
                    }
                    when 'MILS' {
                        output = output.replace('[[MILS]]', '' + System.currentTimeMillis());
                    }
                    when 'RAND' {
                        Decimal rand = getRandomDecimal(0, 10000000000L, 0);
                        output = output.replace('[[RAND]]', '' + rand);
                    }
                    when else {
                        output = output.replace('[[' + match + ']]', record.get(match) + '');
                    }
                }
            } catch(Exception e){
                throw new DataDeskException('Error parsing merge field', e);
            }
        }
        
        return output;
    }
    
    private static List<String> getMergeFields(String input) {
        List<String> matches = new List<String>();
        Pattern pattern = Pattern.compile('\\[\\[(.*?)\\]\\]');
        Matcher matcher = pattern.matcher(input);
        while (matcher.find()) {
            matches.add(matcher.group(1));
        }
        
        return matches;
    }
    
    public static final List<String> celebrityNames = new List<String>{
        'Fifty,Cent',',Drake','Alice,Cooper','Angelina,Jolie','Angus,Young',
            'Axl,Rose','Backstreet,Boys','Ben,Affleck','Beyonce,Knowles','Billy,Joel','Bon,Scott',
            'Brad,Pitt','Brian,Johnson','Britney,Spears','Bruce,Springsteen','Bruce,Willis',
            'Bruce,Springsteen','Celine,Dion','Cristiano,Ronaldo','Dan,Brown','David,Bowie',
            'David,Beckham','Doctor,Dre','Dwayne,Johnson','Ed,Sheeran','Eddie,Vedder',
            'Ellen,DeGeneres','Elton,John','Eric,Clapton','Floyd,Mayweather Jr.',
            'Floyd,Mayweather','Freddie,Mercury','Garth,Brooks','Gene,Simmons','George,Lucas',
            'George,Clooney','Harrison,Ford','Howard,Stern','J.K.,Rowling',
            'James,Cameron','James,Patterson','Janis,Joplin','Jay,Z','Jennifer,Aniston','Jennifer,Lopez',
            'Jerry,Seinfeld','Jim,Morrison','Jimi,Hendrix','Joan,Jett','John,Lennon','Johnny,Depp',
            'Jon,Bon Jovi','Judge,Judy Sheindlin','Julia,Roberts','Justin,Bieber','Kanye,West',
            'Katy,Perry','Kevin,Hart','Kim,Kardashian','Kobe,Bryant','Kurt,Cobain','Kylie,Jenner',
            'Lady,Gaga','LeBron,James','Lemmy,Kilmister','Leonardo,DiCaprio','Lionel,Messi','Manny,Pacquiao',
            'Mariah,Carey','Mel,Gibson','Michael,Jordan','Mick,Jagger','Oprah,Winfrey','Ozzy,Osbourne',
            'Paul,McCartney','Paul,McCartney','Paula,Deen','Phil,McGraw','Robert,Plant','Robert,Downey Jr.',
            'Robin,Williams','Roger,Daltrey','Roger,Federer','Ronnie,JamesDio','Rush,Limbaugh','Sandra,Bullock',
            'Saul,Canelo Alvarez','Sean,Diddy Combs','Shaquille,O\'Neal','Simon,Cowell','Spice,Girls','Steven,Tyler',
            'Steven,Spielberg','Taylor,Swift','The,Weeknd','Tiger,Woods','Tom,Petty','Tom,Hanks','Tom,Cruise',
            'Tyler,Perry',',Eminem',',Cher',',Bono',',Rihanna',',Adele','Jimmers,Dudeman','Ronald,Washington',
            'Chip,Digster','Saucy,Thompson','Theresa,Recording','Marcus,Unread','Stella,Artois','Alexander,The Great'
     };
}
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
    public static String getRandomComment() {
        // generate random index between 0 and the number of celebrity names - 1
        return getValueAtRandomIndex(comments);
    }
//
// getRandomName
//
    public static String[] getRandomName() {
        // generate random index between 0 and the number of celebrity names - 1
        return DD_Util.split(getValueAtRandomIndex(celebrityNames));
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
            
            if (range.size() > 1){
            	endDate = Date.valueOf(range[1]);     
        		daysBetween = startDate.daysBetween(endDate);
            	addDays = startDate == endDate ? 0 : Math.round(Math.random() * daysBetween);
        		return startDate.addDays(addDays);
            } else {
                return startDate;
            }
        } catch(Exception e){
            throw new DataDeskException('Error parsing date parameters : ' + rangeString, e);
        }
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
// getValueAtRandomIndex
//
    public static String getValueAtRandomIndex(String[] stringList){
        if (!stringList?.isEmpty()){
        	return stringList[getRandomIndex(stringList)];
        } else {
            return '';
        }
    }
//
// getRandomIndex
//
    public static Integer getRandomIndex(Object[] oList){
        Integer returnVal;
        try {
            returnVal = (Integer)getRandomDecimal(0, oList.size() - 1, 0);
        } catch(Exception e){
            throw new DataDeskException('Error calculating random index : getRandomIndex : ' + oList);
        }
        return returnVal;
    }
//
// setValue
//   

    public static void setValue(sObject record, Schema.DescribeFieldResult fieldDescribe, String value){
        setValue(record, fieldDescribe, new List<String>{ value });
    }
    
    public static void setValue(sObject record, Schema.DescribeFieldResult fieldDescribe, List<String> valueList){
        
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
        
        Decimal value;
        
        try {
            if (isList){
            	record.put(fieldName, getValueAtRandomIndex(valueList));
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_BOOLEAN){
                
                record.put(fieldName, Boolean.valueOf(getRandomDecimal(0,1,0)));
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_DATE){
                record.put(fieldName, getRandomDate(valueList[0]));
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_DATETIME){
                
                record.put(fieldName, getRandomDateTime(valueList[0]));
                
            } else if (dataType == DD_Util.DISPLAY_TYPE_PHONE){
                
                record.put(fieldName, String.valueOf(getRandomDecimal(10000000000L,19999999999L,0)));
                
			} else if (isNumber){
                
                value = getRandomDecimal(valueList[0]);
                
                if (dataType == DD_Util.DISPLAY_TYPE_INTEGER){
                    record.put(fieldName, Integer.valueOf(value));
                } else if (dataType == DD_Util.DISPLAY_TYPE_DOUBLE 
                           || dataType == DD_Util.DISPLAY_TYPE_CURRENCY){
                	record.put(fieldName, Double.valueOf(value));
                } else {
                	record.put(fieldName, (Decimal)value); 
                }               
                
            } else {
                String stringValue = valueList[0];
                
                if (fieldName.contains('Email'))
                    stringValue = stringValue.replace(' ', '_').replace(',', '_');
                
                record.put(fieldName, getMergeValue(record, stringValue));
            }
            
        } catch(Exception e){
            throw new DataDeskException('Error setting object value : ' + fieldName + ' : ' + value, e);
        }
    }

    public static String getMergeValue(sObject record, String input){
        String output = input, replacementValue;
        String[] name = getRandomName();
        
        for (String match : parseMergeFields(output)){
            try {
                if (match.contains('FNAME')){
                    replacementValue = name[0];
                    
                } else if (match.contains('LNAME')){
                    
                    replacementValue = name[1];
                    
                } else if (match.contains('COMMENT')){
                    
                    replacementValue = getValueAtRandomIndex(comments);
                    
                } else if (match.contains('TITLE')){
                    
                    replacementValue = getValueAtRandomIndex(titles);
                    
                } else if (match.contains('RAND')){
                    
                    replacementValue = String.valueOf(getRandomDecimal(match.replace('RAND|', '')));
                    
                } else {
                	replacementValue = String.valueOf(record.get(match));
                }
                
                output = output.replace('[[' + match + ']]', replacementValue);
            } catch(Exception e){
                throw new DataDeskException('Error parsing merge field. Check formatting. Match : ' + match + ' : input : ' + input, e);
            }
        }
        
        return output;
    }
    
    public static List<String> parseMergeFields(String input) {
        List<String> matches = new List<String>();
        Pattern pattern = Pattern.compile('\\[\\[(.*?)\\]\\]');
        Matcher matcher = pattern.matcher(input);
        while (matcher.find()) {
            matches.add(matcher.group(1));
        }
        
        return matches;
    }
    
    public static final List<String> celebrityNames = new List<String>{
        'Fifty|Cent','|Drake','Alice|Cooper','Angelina|Jolie','Angus|Young',
            'Axl|Rose','Backstreet|Boys','Ben|Affleck','Beyonce|Knowles','Billy|Joel','Bon|Scott',
            'Brad|Pitt','Brian|Johnson','Britney|Spears','Bruce|Springsteen','Bruce|Willis',
            'Bruce|Springsteen','Celine|Dion','Cristiano|Ronaldo','Dan|Brown','David|Bowie',
            'David|Beckham','Doctor|Dre','Dwayne|Johnson','Ed|Sheeran','Eddie|Vedder',
            'Ellen|DeGeneres','Elton|John','Eric|Clapton','Floyd|Mayweather Jr.',
            'Floyd|Mayweather','Freddie|Mercury','Garth|Brooks','Gene|Simmons','George|Lucas',
            'George|Clooney','Harrison|Ford','Howard|Stern','J.K.|Rowling',
            'James|Cameron','James|Patterson','Janis|Joplin','Jay|Z','Jennifer|Aniston','Jennifer|Lopez',
            'Jerry|Seinfeld','Jim|Morrison','Jimi|Hendrix','Joan|Jett','John|Lennon','Johnny|Depp',
            'Jon|Bon Jovi','Judge|Judy Sheindlin','Julia|Roberts','Justin|Bieber','Kanye|West',
            'Katy|Perry','Kevin|Hart','Kim|Kardashian','Kobe|Bryant','Kurt|Cobain','Kylie|Jenner',
            'Lady|Gaga','LeBron|James','Lemmy|Kilmister','Leonardo|DiCaprio','Lionel|Messi','Manny|Pacquiao',
            'Mariah|Carey','Mel|Gibson','Michael|Jordan','Mick|Jagger','Oprah|Winfrey','Ozzy|Osbourne',
            'Paul|McCartney','Paul|McCartney','Paula|Deen','Phil|McGraw','Robert|Plant','Robert|Downey Jr.',
            'Robin|Williams','Roger|Daltrey','Roger|Federer','Ronnie|James Dio','Rush|Limbaugh','Sandra|Bullock',
            'Saul|Canelo Alvarez','Sean|Diddy Combs','Shaquille|O\'Neal','Simon|Cowell','Spice|Girls','Steven|Tyler',
            'Steven|Spielberg','Taylor|Swift','The|Weeknd','Tiger|Woods','Tom|Petty','Tom|Hanks','Tom|Cruise',
            'Tyler|Perry','|Eminem','|Cher','|Bono','|Rihanna','|Adele','Jimmers|Dudeman','Ronald|Washington',
            'Chip|Digster','Saucy|Thompson','Theresa|Recording','Marcus|Unread','Stella|Artois','Alexander|The Great'
     };
         
    public static final List<String> comments = new List<String>{
        'I need a vacation', 'I\'m getting too old for this', 'Where did I put my keys?', 
            'Make sure you absolutely never, under any circumstances', 'The suspense is killing me', 
            'The silence is deafening', 'I need a drink', 'Please don\'t break', 'If you need me, I\'ll be in the woods',
            'Oy vey!', 'Dios mio', 'Uh oh', 'Yowza', 'Cowabunga', 'Surf\'s up', 'Here we go', 'WHOA', 'Saddle up', 'Buckle up',
            'Oh gawd', '*Runs away*', 'Take cover!!', 'Nobody cares', 'Oh, the humanity!', 'I live for the drama',
            'YOLO', 'Time for lunch', '10/10 will do again', 'Baby Einstein Approved', 'I\'m going to regret this',
            'Welp, it\'s over', 'Let\'s try and be professional, here', 'Please try to contain your excitement', 
            '*Holds breath*', 'HOLD', 'Brace yourself', 'Check yourself before you wreck yourself', 'Don\'t start none, won\'t be none',
            'The cat\'s out of the bag!', 'My dad could beat up your dad', 'I\'m so cold', 'Ok let\'s all just try and chill out', 'EVERYONE REMAIN CALM'
     };    
         
    public static final List<String> titles = new List<String>{
        'Doctor', 'Professor', 'The Man with the Plan', 'Vice President', 
        'The Amazing', 'The Mysterious', 'The Great', 'The Real'
     };         
}
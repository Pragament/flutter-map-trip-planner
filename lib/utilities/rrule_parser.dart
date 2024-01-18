

Map<String, Object> rruleParser(String rrule)
{
  String newRule = rrule.replaceAll('RRULE:', '');
  List<List<String>> data = (newRule.split(';')).map((item) => item.split('=')).toList();
  Map<String, Object> parsedRRule = {};
  print('DATA : $data');
  print('DATA : ${data.length}');
  print('DATA : ${data[0].length}');
  if(data.length != 1)
    {
      for(final i in data)
      {
        if(i[0].trim() == 'UNTIL')
        {
          DateTime date = DateTime(int.parse(i[1].substring(0,4)), int.parse(i[1].substring(4,6)), int.parse(i[1].substring(6)));
          parsedRRule[i[0]] = date;
          continue;
        }
        if(i[0].trim() == 'INTERVAL')
        {
          parsedRRule[i[0]] = int.parse(i[1]);
          continue;
        }
        if(i[0].trim() == 'BYMONTH')
        {
          parsedRRule[i[0]] = int.parse(i[1]);
          continue;
        }
        if(i[0].trim() == 'BYMONTHDAY')
        {
          parsedRRule[i[0]] = int.parse(i[1]);
          continue;
        }
        if(i[0].trim() == 'NEVER')
        {
          continue;
        }
        parsedRRule[i[0]] = i[1];
      }
    }
  return parsedRRule;
}


#!bin/bash
res=`lsof -i :4567`
regex="ruby"
if ! [[ $res =~ $regex ]] 
then 
 ruby /Library/WebServer/Documents/prop/GeoProposal/Sinatra/sinatrapp.rb 
fi


echo "Sinatra is already alive." 

# de.marcbender.nsfw

Titanium module for iOS and Android for NSFW image detection (not safe for work)
The module uses two different recognition models for more precise detection.
Opensource code from different sources are used (sources will be added later), also the models used are opensource....
For iOS CoreML is used, Android uses Tensorflow Lite models

## Example

```js

var NSFW_MODULE = require('de.marcbender.nsfw');

function nsfwChecker(blob,callback){

      var thisCheckFunction = function(nsfwResultObject) {
        console.log("");
        console.log("");
        console.log("++++++++++++++++++++++++++++++++++++++++++++++");
        console.log("NSFW_MODULE RESULT: "+JSON.stringify(nsfwResultObject));
        console.log("++++++++++++++++++++++++++++++++++++++++++++++");
        console.log("");

        var result = nsfwResultObject.class;

        NSFW_MODULE.removeEventListener('classification', thisCheckFunction);

        if (result){
          if ((result.second.classLabel == "Sexy" && result.identifier == "NSFW") || (result.second.classLabel == "Sexy" && result.identifier == "SFW")){

            if (result.identifier == "SFW" && result.confidence > 0.50){
              //callback('SFW_');
              console.log("Image is SFW");
            }
            else {
              //callback('SEXY_');
              console.log("Image is SEXY");
            }
          }
          else if ((result.confidence > 0.50 && result.identifier == "NSFW") || result.second.classLabel == "Porn"){
            //callback('NSFW_');
	        console.log("Image is NSFW");
          }
          else {
            if (result.identifier == "SFW" && ((Number(result.confidence - result.second.output.Sexy) < 0.5) || (Number(result.confidence - result.second.output.Porn) < 0.5))){
              //callback('NSFW_');
   	          console.log("Image is NSFW");
            }
            else if (result.identifier == "SFW" && ((Number(result.confidence - result.second.output.Sexy) < 0.5))){
              //callback('SEXY_');
              console.log("Image is SEXY");
            }
            else {
              //callback('SFW_');
              console.log("Image is SFW");
            }
          }
        }
        else {
          //callback('SFW_');
          console.log("Image is SFW");
        }
      }
      NSFW_MODULE.addEventListener('classification', thisCheckFunction);

      NSFW_MODULE.checkImage({
      	image:blob
      });

      result = null;
}


var callbackfunction = function(){};

nsfwChecker(imageBlob,callbackfunction);


```


## Events
* `classification` - returns image classification

## Methods
* `checkImage({image:image_blob})`




## Author

- Marc Bender ([@mbender74](https://github.com/mbender74/))

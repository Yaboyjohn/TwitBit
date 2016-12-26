// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .


var map;
function initMap() {
  // Constructor creates a new map - only center and zoom are required.
  map = new google.maps.Map(document.getElementById('map'), {
    //random center we will change it later
    center: {lat: 33.973234, lng: -118.037546},
    zoom: 5

//first is up and down
//second is left to right
//(34.052234, -118.243685)
//(40.783060, -73.971249)
  });
  //grab the array from the rb file
  var coordinates = gon.locations
  //the bounds we will extend with the coordinates we deal with later
  var bounds = new google.maps.LatLngBounds();
  for (var i = 0; i < coordinates.length; i++) {
    //see how many unique places we get
    var unique_locations_array = [];
    //the array where we store the 4 corners of coordinates given by the twitter rectangle
    var positions_array = [];
    //first corner
    var first_corner_lat = coordinates[i][0][1];
    var first_corner_long = coordinates[i][0][0];
    //second corner
    var sec_corner_lat = coordinates[i][1][1];
    var sec_corner_long = coordinates[i][1][0];
    //third corner
    var third_corner_lat = coordinates[i][2][1];
    var third_corner_long = coordinates[i][2][0];
    //fourth corner
    var four_corner_lat = coordinates[i][3][1];
    var four_corner_long = coordinates[i][3][0];

    //make LatLng objects for each of the corners
    var corner1 = new google.maps.LatLng(first_corner_lat, first_corner_long);
    var corner2 = new google.maps.LatLng(sec_corner_lat, sec_corner_long);
    var corner3 = new google.maps.LatLng(third_corner_lat, third_corner_long);
    var corner4 = new google.maps.LatLng(four_corner_lat, four_corner_long);
    //add them all to the positions array
    positions_array.push(corner1);
    positions_array.push(corner2);
    positions_array.push(corner3);
    positions_array.push(corner4);
    //create the new rectangle to be displayed on the map
    var overlay = new google.maps.Polygon({
        paths: positions_array,
        strokeColor: '#FF0000',
        strokeOpacity: 0.8,
        strokeWeight: 2,
        fillColor: '#FF0000',
        fillOpacity: 0.1
      });
      //place this rectangle on the map
      overlay.setMap(map);
      //extend the map bounds to fit in these locations
      bounds.extend(corner1);
      bounds.extend(corner2);
      bounds.extend(corner3);
      bounds.extend(corner4);
    }
    //reset the positions array to empty for the next location
    positions_array = [];
    //make the map fit to these new bounds
    map.fitBounds(bounds);
    var errors = gon.misspelled_words;
    total_errors = errors.length;
    var total = gon.total

    //generate the score for this user
    var score = Math.round(total_errors/total * 1000) / 1000;
    //this has filler text but will be updated based off of user score
    var categoryName = document.getElementById('comparison-category');

    //robot < .03
    if (score < .030) {
      $('#comparison-image').attr('src', "http://disneydigitalstudio.com/wp-content/uploads/2014/11/Baymax-Poster-e1416440487417.jpg")
      categoryName.innerHTML = "Robot";
    }
    //politician
    else if ((score >= .030) && (score < .060)) {
      $('#comparison-image').attr('src', "https://pbs.twimg.com/profile_images/738744285101580288/OUoCVEXG.jpg")
      categoryName.innerHTML = "Politician";
    }
    //athlete
    else if ((score >= .060) && (score < .080)) {
      $('#comparison-image').attr('src', "http://img.wennermedia.com/620-width/kobe-bryant-zoom-1600bda7-b795-4122-9832-61388909843b.jpg")
      categoryName.innerHTML = "Athlete";
    }
    //also politician
    else if ((score >= .080) && (score < .100)) {
      $('#comparison-image').attr('src', "https://pbs.twimg.com/profile_images/738744285101580288/OUoCVEXG.jpg")
      categoryName.innerHTML = "Politician";
    }
    //normal person
    else if ((score >= .100) && (score < .150)) {
      $('#comparison-image').attr('src', "https://upwardsleader.files.wordpress.com/2016/06/pretty-woman-with-thumbs-up.jpg")
      categoryName.innerHTML = "Average Person";
    }
    //rapper
    else if (score >= .150) {
      $('#comparison-image').attr('src', "http://ima.ulximg.com/image/src/cover/1412153812_013b5b00eca4c8ffbf56921deed3b8b8.jpg/cb441eb8fd42e8298b5a579a7752dd75/1412153812_snoop_101_78.jpg")
      categoryName.innerHTML = "Rapper";
    }
    //score doens't fall into any category make it normal person
    else {
      $('#comparison-image').attr('src', "https://upwardsleader.files.wordpress.com/2016/06/pretty-woman-with-thumbs-up.jpg")
      categoryName.innerHTML = "Average Person";
    }
    //create this dummy score that contains the actual score value; needed for animation calculations
    var dummyscore = document.getElementById('dummyscore');
    dummyscore.innerHTML = score;
    newdummyscore = dummyscore.innerHTML;

    //function to determine the background for tweet times
    var most_frequent = 0
    var most_frequent_name = ""
    for (var key in gon.tweet_times) {
      if (gon.tweet_times[key] > most_frequent) {
        most_frequent = gon.tweet_times[key];
        most_frequent_name = key;
      }
    }

    //set the background of the data page based on most popular tweet time
    var dataPage = document.getElementById('data-page');
    if (most_frequent_name == "super_early_morning") {
      dataPage.style.backgroundImage = 'url(http://media.gettyimages.com/videos/an-early-morning-red-skyline-of-new-york-city-video-id160669828?s=640x640)';
    }
    else if (most_frequent_name == "morning") {
      dataPage.style.backgroundImage = 'url(http://img.wallpaperfolder.com/f/54550F1D0253/bright-sunshine-gt-backgrounds.jpg)';
    }
    else if (most_frequent_name == "afternoon") {
      dataPage.style.backgroundImage = 'url(http://www.wallcoo.net/nature/amazing%20hd%20landscapes%20wallpapers/images/%5Bwallcoo_com%5D_Blissful_Late_Afternoon.jpg)';
    }
    else if (most_frequent_name == "evening") {
      dataPage.style.backgroundImage = 'url(http://pre12.deviantart.net/97ef/th/pre/i/2012/315/d/7/november_10st_evening_after_rainy_day_in_arcipelag_by_eskile-d5knphw.jpg)';
    }
    else if (most_frequent_name == "night") {
      dataPage.style.backgroundImage = 'url(http://img.wallpaperfolder.com/f/70F554D65D6D/sky-shinny-moon-night.jpg)';
    }
    else {
      dataPage.style.backgroundImage = 'url(http://orig08.deviantart.net/82fa/f/2013/049/c/0/night_stars_by_vronde-d5vdak6.png)';
    }

    var best_friends = gon.mentions;
    var first_friend_object = best_friends[0];
    var second_friend_object = best_friends[1];
    var third_friend_object = best_friends[2];

    var first_place_name = document.getElementById("first-place-name");
    first_place_name.innerHTML = first_friend_object[0];
    var first_place_pic = document.getElementById("first-place-pic");
    first_place_pic.style.backgroundImage = 'url('+first_friend_object[2]+')';

    var second_place_name = document.getElementById("second-place-name");
    second_place_name.innerHTML = second_friend_object[0];
    var second_place_pic = document.getElementById("second-place-pic");
    second_place_pic.style.backgroundImage = 'url('+second_friend_object[2]+')';

    var third_place_name = document.getElementById("third-place-name");
    third_place_name.innerHTML = third_friend_object[0];
    var third_place_pic = document.getElementById("third-place-pic");
    third_place_pic.style.backgroundImage = 'url('+third_friend_object[2]+')';

    //function to create the counter generating the score
    jQuery.fn.extend({
      animateCount : function (from, to, time) {
        var steps = .001,
            self = this,
            counter;
        if (from - to > 0) {
          steps = -1;
        };
        from -= steps;
        function step() {
          self.text(Math.round(((from += steps) * 1000)) / 1000);
          if ((steps < 0 && to >= from) || (steps > 0 && from >= to)) {
            clearInterval(counter);
          };
        };
        counter = setInterval(step, time || 100);
        counter.attr('id', 'counter');
      }
    });
    $('#score').animateCount(.001, score, 7);
  }

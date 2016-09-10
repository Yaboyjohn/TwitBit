$(document).ready(function () {
    $input = $('input#search-box');
    $input.click(function() {
      $input.attr("value", "");
      $input.css("color", "black");
    });

});

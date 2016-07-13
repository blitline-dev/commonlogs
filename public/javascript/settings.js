$(function(){

 /* $("#add-credentials").click(function() {
    $("#credform").removeClass("hidden");
    return true;
  });*/

  $("#all").click(function() {
    $("#loglist input").prop('checked', true);
  });

  $("#none").click(function() {
    $("#loglist input").prop('checked', false);
  });

  $('#myModal').on('shown.bs.modal', function () {
    $('#myModal form').validator('destroy')
    var validator = $('#myModal form').validator();
      validator.on('submit', function (e) {
        if (e.isDefaultPrevented()) {
          // handle the invalid form...
          alert("Please correct the form errors before continuing");
          return false;
        }
      });
  })
  
  $("#updateSettings").click(function() {
    var submitData = getFormData();

    $.ajax({
      method: "POST",
      url: "/settings",
      data: submitData,
      success: function() {
        swal('Saved', '', 'success');
      },
      error: function (xhr, exception, error) {
        console.dir[xhr, exception, error]
        swal('Nope', 'The webhook didn\'t work\n', 'error');
      },
      dataType: "json"
    });

  });

  function getFormData() {
    var data = {};

    data["autodelete"] = $("#autodelete").is(':checked');
    data["selflog"] = $("#selflog").is(':checked');

    return data;    
  }

  function addIfValueExists(hash, id) {
    var selector = "#" + id;
    if ($(selector).val().length > 0) {
      hash[id] = $(selector).val();
    }
  }

  function validateFormData(data) {
    if (data["iam_key"] || data["iam_secret"] || data["bucket"] ) {
      if (!(data["iam_key"] && data["iam_secret"] && data["bucket"])) {
        return false;
      }
    }
    return true;
  }

});
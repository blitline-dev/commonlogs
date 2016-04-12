$(function(){

  function loadData() {
    $.ajax({
      method: "GET",
      url: "/notifications?name=" + rocketLog.name + "&event=" + rocketLog.eventName,
      success: function(data) {
        console.dir(data);
        $("#webhookUrl").val(data.type_data.webhook);
        var checked = (data.type_data.context == "true");
        if (!checked) {
          $("#r3").removeAttr('checked');
        }
        $("#na").val(parseInt(data.notify_after, 10));
        $("#nm").val(parseInt(data.notify_max, 10));
      },
      error: function (xhr, exception, error) {
        console.dir[xhr, exception, error]
        swal('Nope', 'Failed to get data from server', 'error');
      },
      dataType: "json"
    });
  }

  function createNotification() {
    var webhookUrl = $("#webhookUrl").val();
    var context = $("#r3").is(':checked');
    var notifyAfter = $("#na").val();
    var notifyMax = $("#nm").val();

    $.ajax({
      method: "POST",
      url: "/notifications",
      data: {
        "name" : rocketLog.name,
        "event" : rocketLog.eventName,
        "notifyMax" : notifyMax,
        "notifyAfter" : notifyAfter,
        "webhookUrl" : webhookUrl,
        "context" : context
      },
      success: function() {
        swal('Saved', '', 'success');
      },
      error: function (xhr, exception, error) {
        console.dir[xhr, exception, error]
        swal('Nope', 'The webhook didn\'t work\n', 'error');
      },
      dataType: "json"
    });
  }

  function deleteNotification() {

    $.ajax({
      method: "DELETE",
      url: "/notifications/" + id,
      data: {},
      success: function() {
        swal('OK!', 'The webhook completed successfully', 'success');
      },
      error: function (xhr, exception, error) {
        console.dir[xhr, exception, error]
        swal('Nope', 'The webhook didn\'t work\n', 'error');
      },
      dataType: "json"
    });
  }

  function showHideTest() {
    $("#testUrl").hide();
    /*
    if ($("#webhookUrl").val().toString().length > 0) {
      $("#testUrl").show();
    }else {
      $("#testUrl").hide();
    } */
  }

  function sendTest() {
    $('[data-toggle="popover"]').popover();
    var sample = buildSampleWebhookJSON();
    var type = $("#wm").text();

    $.ajax({
      method: type,
      url: $("#webhookUrl").val(),
      data: sample,
      success: function() {
        swal('OK!', 'The webhook completed successfully', 'success');
      },
      error: function (xhr, exception, error) {
        console.dir[xhr, exception, error]
        swal('Nope', 'The webhook didn\'t work\n', 'error');
      },
      dataType: "json"
    });
  }

  function buildSampleWebhookJSON() {
    var sample = {
      "timestamp" : Date.now(),
      "event_name" : "eventName",
      "log_entry" : "Some Log Event..."
    }

    if($("#r3").is(':checked')) {
      sample["context"] = [
        "3 lines before event",
        "2 lines before event",
        "1 line before event",
        "Some Log Event...",
        "1 lines after event",
        "2 lines after event",
        "3 lines after event",
      ]
    }
    return sample;
  }

  $("#createButton").click(createNotification);
  $('#cancel').click(function(){ window.location="event_manager?name=" + rocketLog.name});
  $("#testUrl").click(sendTest);
  $("#webhookUrl").keypress(showHideTest);
  $("#webhookUrl").focusout(showHideTest);
    
  loadData();
});

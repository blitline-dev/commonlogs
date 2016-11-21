$(function(){

  function loadData() {
    $.ajax({
      method: "GET",
      url: "/notifications?name=" + encodeURIComponent(commonLog.name) + "&event=" + encodeURIComponent(commonLog.eventName),
      success: function(data) {
        console.dir(data);
        if (data.ntype == "webhook") {
          $("#webhookUrl").val(data.type_data.webhooks);
          $('.nav-pills a[href="#webhook"]').tab('show');
        }else if (data.ntype == "slack") {
          $("#sw").val(data.type_data.slack_webhook);
          $('.nav-pills a[href="#slack"]').tab('show');
        }else {
          $("#webhookUrl").val(data.type_data.webhooks);
          $('.nav-pills a[href="#webhook"]').tab('show');          
        }
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

  function getSlackData() {
    var webhookUrl = $("#sw").val();
    var context = $("#r3").is(':checked');
    var notifyAfter = $("#na2").val();
    var notifyMax = $("#nm2").val();

    var submitData = {
        "name" : commonLog.name,
        "event" : commonLog.eventName,
        "ntype" : "slack",
        "notifyMax" : notifyMax,
        "notifyAfter" : notifyAfter,
        "context" : context,
        "sw" : webhookUrl
      };

    return submitData;
  }

  function getWebhookData() {
    var webhookUrl = $("#webhookUrl").val();
    var context = $("#r3").is(':checked');
    var notifyAfter = $("#na").val();
    var notifyMax = $("#nm").val();

    var submitData = {
      "name" : commonLog.name,
      "event" : commonLog.eventName,
      "ntype" : "webhook",
      "notifyMax" : notifyMax,
      "notifyAfter" : notifyAfter,
      "webhookUrl" : webhookUrl,
      "context" : context
    };
    return submitData;
  }

  function validateSlackData() {
    var webhookValue = $("#sw").val();
    if (!webhookValue) {
      swal('Set Webhook', 'You must set a Slack webhook value', 'error');
      return false
    }

    if (!webhookValue.startsWith("http")) {
      swal('Set Webhook', 'Slack webhook must be http or https', 'error');
      return false;
    }
    return true;
  }

  function validateWebhookData() {
    var webhookValue = $("#webhookUrl").val();
    if (!webhookValue) {
      swal('Set Webhook', 'You must set a webhook value', 'error');
      return false
    }

    if (!webhookValue.startsWith("http")) {
      swal('Set Webhook', 'Webhook must be http or https', 'error');
      return false;
    }
    return true;
  }

  function createNotification() {

    var $tab = $(".bhighlight.active");
    var ntype = $tab.attr("data-name");
    var submitData = null;

    if (ntype == "slack") {
      if (!validateSlackData()) {
        return false;
      }
      submitData = getSlackData();
    }else if (ntype == "webhook") {
      if (!validateWebhookData()) {
        return false;
      }
      submitData = getWebhookData();
    }

    if (!submitData) {
      console.log("No tab selected");
    }

    $.ajax({
      method: "POST",
      url: "/notifications",
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
  }

  function hideShowActionButtons() {
    if ($("#webhookUrl").val().toString().length == 0 && $("#sw").val().toString().length == 0) {
      $("#createButton").prop('disabled', true);
    }else {
      $("#createButton").prop('disabled', false);
    }
  }

  function showHideTest() {
    hideShowActionButtons();
    $("#testUrl").hide();
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

  // ------- Log Group Switch
  $(".group").click(function() {
    eventChanged($(this));
    return false;
  });

  function eventChanged($el) {
    var name = $el.attr("data-group");
    var url = "event_manager?name=" + name;
    window.location = url;
  }
  // ------- End Group Switch


  $("#createButton").click(createNotification);
  $('#cancel').click(function(){ window.location="event_manager?name=" + commonLog.name});
  $("#testUrl").click(sendTest);
  $("#webhookUrl").keypress(showHideTest);
  $("#webhookUrl").focusout(showHideTest);
    
  $('.nav-tabs a[href="#webhook"]').tab('show');

  loadData();
  hideShowActionButtons();
});

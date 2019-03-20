$(document).on('show.bs.modal', '#import-summary, #import-log', function(event) {
  var importId = $(event.relatedTarget).data('id');
  var $modal = $(event.target);

  $modal.find('.import-summary, .import-log').hide();
  $modal.find('#import_summary_' + importId + ', #import_log_' + importId).show();
});

# 0001-call-ipts_send_feedback-in-handle_outputs-only-when-.patch

## warning: ‘transaction_id’ may be used uninitialized in this function

```
drivers/misc/ipts/ipts-hid.c: In function ‘ipts_handle_processed_data’:
drivers/misc/ipts/ipts-hid.c:433:7: warning: ‘transaction_id’ may be used uninitialized in this function [-Wmaybe-uninitialized]
   ret = ipts_send_feedback(ipts, parallel_idx, transaction_id);
   ~~~~^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drivers/misc/ipts/ipts-hid.c:352:6: note: ‘transaction_id’ was declared here
  u32 transaction_id;
      ^~~~~~~~~~~~~~
```

## The patched code will look like this
```c
static int handle_outputs(ipts_info_t *ipts, int parallel_idx)
{
	kernel_output_buffer_header_t *out_buf_hdr;
	ipts_buffer_info_t *output_buf, *fb_buf = NULL;
	u8 *input_report, *payload;
	u32 transaction_id;
	int i, payload_size, ret = 0, header_size;

	header_size = sizeof(kernel_output_buffer_header_t);
	output_buf = ipts_get_output_buffers_by_parallel_id(ipts, parallel_idx);
	for (i = 0; i < ipts->resource.num_of_outputs; i++) {
		out_buf_hdr = (kernel_output_buffer_header_t*)output_buf[i].addr;
		if (out_buf_hdr->length < header_size)
			continue;

		payload_size = out_buf_hdr->length - header_size;
		payload = out_buf_hdr->data;

		switch(out_buf_hdr->payload_type) {
			case OUTPUT_BUFFER_PAYLOAD_HID_INPUT_REPORT:
				input_report = ipts->hid_input_report;
				memcpy(input_report, payload, payload_size);
				hid_input_report(ipts->hid, HID_INPUT_REPORT,
						input_report, payload_size, 1);
				break;
			case OUTPUT_BUFFER_PAYLOAD_HID_FEATURE_REPORT:
				ipts_dbg(ipts, "output hid feature report\n");
				break;
			case OUTPUT_BUFFER_PAYLOAD_KERNEL_LOAD:
				ipts_dbg(ipts, "output kernel load\n");
				break;
			case OUTPUT_BUFFER_PAYLOAD_FEEDBACK_BUFFER:
			{
				/* send feedback data for raw data mode */
                                fb_buf = ipts_get_feedback_buffer(ipts,
								parallel_idx);
				transaction_id = out_buf_hdr->
						hid_private_data.transaction_id;
				memcpy(fb_buf->addr, payload, payload_size);
				break;
			}
			case OUTPUT_BUFFER_PAYLOAD_ERROR:
			{
				kernel_output_payload_error_t *err_payload;

				if (payload_size == 0)
					break;

				err_payload =
					(kernel_output_payload_error_t*)payload;

				ipts_err(ipts, "error : severity : %d,"
						" source : %d,"
						" code : %d:%d:%d:%d\n"
						"string %s\n",
						err_payload->severity,
						err_payload->source,
						err_payload->code[0],
						err_payload->code[1],
						err_payload->code[2],
						err_payload->code[3],
						err_payload->string);

				goto err_payload;
			}
			default:
				ipts_err(ipts, "invalid output buffer payload\n");
				goto err_payload;
		}
	}

	return 0;

err_payload:
	/*
	 * Calling the "ipts_send_feedback" function repeatedly seems to be
	 * what is causing touch to crash on some platforms, especially on
	 * Surface Pro 4 and Surface Book 1.
	 *
	 * Let's send a feedback only when a payload error occurred.
	 *
	 * Touch and pen issue persists · Issue #374 · jakeday/linux-surface
	 * https://github.com/jakeday/linux-surface/issues/374#issuecomment-508234110
	 */
	if (fb_buf) {
		ipts_err(ipts, "handling payload error\n");
		ret = ipts_send_feedback(ipts, parallel_idx, transaction_id);
		if (ret)
			return ret;
	}

	return 0;
}
```

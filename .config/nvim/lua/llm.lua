-- Configuration
local LLM_MODEL = "claude-3.5-sonnet"

function call_llm()
  -- Check if llm command exists
  if vim.fn.executable('llm') == 0 then
    vim.api.nvim_err_writeln("Error: 'llm' command not found. Please ensure it's installed and in your PATH.")
    return
  end

  local prompt

  -- Check if there's a visual selection
  if vim.fn.mode() == 'v' or vim.fn.mode() == 'V' then
    -- Get the current visual selection
    local _, start_row, start_col, _ = unpack(vim.fn.getpos("'<"))
    local _, end_row, end_col, _ = unpack(vim.fn.getpos("'>"))

    -- Adjust the indices for zero-based indexing
    start_row = start_row - 1
    end_row = end_row - 1
    start_col = start_col - 1
    end_col = end_col - 1

    -- Get the text in the visual selection
    local lines = vim.fn.getline(start_row + 1, end_row + 1)
    if #lines == 0 then
      vim.api.nvim_err_writeln("No lines selected")
      return
    end

    lines[1] = string.sub(lines[1], start_col + 1)
    lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
    prompt = table.concat(lines, "\n")
  else
    -- If no visual selection, use the entire buffer
    prompt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  end

  -- Create a new buffer for the output
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_command('split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Waiting for model " .. LLM_MODEL .. "..."})

  -- Flag to track if we've received any output
  local received_output = false

  -- Function to append lines to the buffer
  local function append_to_buffer(data, is_error)
    vim.schedule(function()
      local lines = vim.split(data, "\n")
      if not received_output then
        -- Clear the buffer before adding the first output
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
        received_output = true
      end
      if is_error then
        lines = vim.tbl_map(function(line) return "Error: " .. line end, lines)
      end
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    end)
  end

  -- Start the job
  local job_id = vim.fn.jobstart({'llm', 'prompt', '-m', LLM_MODEL}, {
    on_stdout = function(_, data)
      if data and #data > 1 or (data[1] and data[1] ~= "") then
        append_to_buffer(table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 1 or (data[1] and data[1] ~= "") then
        append_to_buffer(table.concat(data, "\n"), true)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.schedule(function()
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "LLM command failed with exit code: " .. exit_code})
        end)
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  -- Write the prompt to the job's stdin
  vim.fn.chansend(job_id, prompt)
  vim.fn.chanclose(job_id, "stdin")
end

vim.api.nvim_set_keymap('n', '<leader>ll', ':lua call_llm()<CR>', { noremap = true, silent = false })
vim.api.nvim_set_keymap('v', '<leader>ll', ':<C-u>lua call_llm()<CR>', { noremap = true, silent = false })

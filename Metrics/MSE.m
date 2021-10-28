function mse = MSE(im1,im2)
    if isinteger(im1)     
        im1 = double(im1);
        im2 = double(im2);
    end

    mse = (norm(im1(:)-im2(:),2).^2)/numel(im1);
end

